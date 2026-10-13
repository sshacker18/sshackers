#!/usr/bin/env python3
"""POCO Phone Master: unattended diagnostics and conservative maintenance."""
import os, re, time, hashlib, subprocess
from pathlib import Path
from collections import defaultdict

HOME=Path.home()
SHARED=Path("/storage/emulated/0")
REPORTS=HOME/"phone-master-reports"
REPORTS.mkdir(parents=True,exist_ok=True)
PROTECTED_TERMS=("passport","aadhaar","aadhar","pan card","payslip","pay slip","resume","medical","bank","keystore","signing","private key","id_rsa")
PROTECTED_EXTS={".jks",".keystore",".pem",".p12",".pfx",".key"}
SKIP_DIRS={"Android",".thumbnails",".Trash",".trash"}

def command(cmd,timeout=12):
    try:
        p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
        return p.stdout.strip() or "(no output)"
    except Exception as e: return f"(unavailable: {e})"

def save_report(name,body):
    p=REPORTS/f"{name}-{time.strftime('%Y%m%d-%H%M%S')}.txt"
    p.write_text(body+"\n",errors="replace")
    print(f"Saved report: {p}")

def diagnostics():
    checks=[
      ("TIME / DEVICE",["sh","-c","date; getprop ro.product.model; getprop ro.product.device; getprop ro.build.display.id; uname -a"]),
      ("MEMORY",["sh","-c","grep -E 'MemTotal|MemAvailable|Cached|SwapTotal|SwapFree' /proc/meminfo"]),
      ("CPU LIMITS",["sh","-c","for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_min_freq /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq; do [ -r \"$f\" ] && echo \"$f: $(cat \"$f\")\"; done"]),
      ("CPU FREQUENCIES / GOVERNORS",["sh","-c","for f in /sys/devices/system/cpu/cpu[0-7]/cpufreq/scaling_cur_freq /sys/devices/system/cpu/cpu[0-7]/cpufreq/scaling_governor; do [ -r \"$f\" ] && echo \"$f: $(cat \"$f\")\"; done"]),
      ("TOP",["sh","-c","top -b -n 1 2>&1 | head -n 45"]),
      ("PROCESSES",["sh","-c","ps -A 2>&1 | head -n 100"]),
      ("THERMAL",["sh","-c","for d in /sys/class/thermal/thermal_zone*; do [ -r \"$d/temp\" ] || continue; t=unknown; [ -r \"$d/type\" ] && t=$(cat \"$d/type\"); echo \"$t $(cat \"$d/temp\")\"; done"]),
      ("STORAGE",["df","-h",str(SHARED)]),("SWAP",["cat","/proc/swaps"]),
      ("ADB / ROOT",["sh","-c","getprop init.svc.adbd; getprop service.adb.tcp.port; su -c id 2>&1"])]
    report="\n\n".join("=== "+n+" ===\n"+command(c) for n,c in checks)
    print(report[:14000]); save_report("diagnostics",report)

def cleanup():
    roots=list(dict.fromkeys([HOME/".cache",HOME/"tmp",Path(os.environ.get("TMPDIR",str(HOME/"tmp")))]))
    cutoff=time.time()-7*86400; rows=[]; total=0
    for base in roots:
        if not base.is_dir() or base.is_symlink(): continue
        for root,dirs,files in os.walk(base,followlinks=False):
            dirs[:]=[d for d in dirs if not (Path(root)/d).is_symlink()]
            for name in files:
                p=Path(root)/name
                try:
                    if p.is_symlink() or not p.is_file(): continue
                    st=p.stat()
                    if st.st_mtime<cutoff: rows.append((p,st.st_size)); total+=st.st_size
                except OSError: pass
    allowed=[p.resolve() for p in roots if p.is_dir() and not p.is_symlink()]
    deleted=skipped=0
    for p,_ in rows:
        try:
            q=p.resolve()
            if not any(q!=b and b in q.parents for b in allowed) or p.is_symlink() or not p.is_file() or p.stat().st_mtime>=cutoff:
                skipped+=1; continue
            q.unlink(); deleted+=1
        except OSError: skipped+=1
    report=f"Old Termux cache/scratch files (>7 days): {len(rows)}\nEstimated bytes: {total}\nDeleted: {deleted}\nSkipped: {skipped}\nOnly Termux cache/scratch locations are eligible; shared storage and app data untouched."
    print(report); save_report("cleanup",report)

def process_audit():
    report="TERMUX PROCESS INVENTORY (read-only)\n"+command(["ps","-u",str(os.getuid()),"-o","pid,comm,etime,args"])
    report+="\n\nNo process was killed: unattended mode will not guess which PID is safe to terminate."
    print(report[:12000]); save_report("process-audit",report)

def protected(p):
    return p.suffix.lower() in PROTECTED_EXTS or any(t in p.name.lower() for t in PROTECTED_TERMS)

def normalized(name):
    stem,ext=os.path.splitext(name.lower())
    stem=re.sub(r"\s*(?:\(\s*(?:copy\s*)?\d+\s*\)|\[\s*\d+\s*\]|[-_]copy(?:[-_ ]?\d+)?)\s*$","",stem)
    stem=re.sub(r"\s+copy\s*\d*\s*$","",stem)
    return re.sub(r"\s+"," ",stem).strip(" ._-;()")+ext

def digest(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024),b""): h.update(b)
    return h.hexdigest()

def duplicates():
    if not SHARED.is_dir():
        msg="Shared storage inaccessible; Android storage permission may be required."
        print(msg); save_report("duplicate-audit",msg); return
    print("Scanning shared storage; this can take a while.")
    sizes=defaultdict(list); names=defaultdict(list); errors=0
    for root,dirs,files in os.walk(SHARED,followlinks=False):
        dirs[:]=[d for d in dirs if d not in SKIP_DIRS and not (Path(root)/d).is_symlink()]
        for name in files:
            p=Path(root)/name
            try:
                if p.is_symlink() or not p.is_file(): continue
                s=p.stat().st_size
                if s<=0: continue
                sizes[s].append(p); names[normalized(name)].append(p)
            except OSError: errors+=1
    hashes=defaultdict(list)
    for size,paths in sizes.items():
        if len(paths)<2: continue
        for p in paths:
            try: hashes[(size,digest(p))].append(p)
            except OSError: errors+=1
    groups=[g for g in hashes.values() if len(g)>1]
    similar=[g for g in names.values() if len(g)>1]
    plan=[]; out=["EXACT DUPLICATES (SHA-256 verified)"]
    for i,g in enumerate(groups,1):
        out.append(f"\nGROUP {i}:")
        for p in g: out.append(f"  {p}"+(" [PROTECTED NAME]" if protected(p) else ""))
    out.append("\nSIMILAR NAMES (report-only; never deleted by name alone)")
    for g in similar: out.append("  GROUP: "+" | ".join(map(str,g)))
    skipped_groups=0
    for g in groups:
        if any(protected(p) for p in g): skipped_groups+=1; continue
        keeper=sorted(g,key=lambda p:(normalized(p.name)!=p.name.lower(),len(str(p)),str(p)))[0]
        plan.extend((p,keeper) for p in g if p!=keeper)
    deleted=skipped=0
    for p,k in plan:
        try:
            if p.is_symlink() or k.is_symlink() or not p.is_file() or not k.is_file() or p.stat().st_size!=k.stat().st_size or digest(p)!=digest(k):
                skipped+=1; continue
            p.unlink(); deleted+=1
        except OSError: skipped+=1
    out += ["",f"Exact duplicate groups: {len(groups)}",f"Protected groups skipped: {skipped_groups}",f"Verified duplicate copies deleted: {deleted}",f"Skipped/changed files: {skipped}",f"Read errors: {errors}","Similar-name candidates are never deleted automatically.","Android private/app data and OBB, Android folders, thumbnails and trash folders excluded."]
    report="\n".join(out); print(report[:22000]); save_report("duplicate-audit",report)

def battery_flow():
    script = Path(__file__).with_name("battery_flow.sh")
    if not script.is_file():
        raise FileNotFoundError(f"Battery Flow script not found: {script}")
    print("Starting read-only battery diagnosis and recommendations...")
    p = subprocess.run(["bash", str(script)], text=True)
    if p.returncode != 0:
        print(f"Battery Flow exited with status {p.returncode}. Check its report for details.")

def run_all():
    print("\n=== END-TO-END START ===")
    status=[]
    for name,fn in [("Diagnostics",diagnostics),("Termux cache cleanup",cleanup),("Process inventory",process_audit),("Duplicate scan/cleanup",duplicates),("Battery diagnosis and optimization recommendations",battery_flow)]:
        print(f"\n=== {name} ===")
        try: fn(); status.append(name+": completed")
        except Exception as e: status.append(name+f": ERROR {type(e).__name__}: {e}"); print(status[-1])
    index=command(["ls","-lht",str(REPORTS)])
    print("\n=== SAVED REPORTS ===\n"+index); save_report("report-index",index)
    summary="END-TO-END SUMMARY\n"+"\n".join(status)+"\nSaved reports: listed"
    print(summary); save_report("end-to-end-summary",summary)

def menu():
    while True:
        print("\n======= POCO PHONE MASTER =======\n1. Exit\n2. Run end-to-end\n=================================")
        choice=input("Choose 1-2: ").strip()
        if choice=="1": print("Phone Master exited."); return
        if choice=="2": run_all()
        else: print("Invalid choice. Enter 1 or 2.")

if __name__=="__main__": menu()
