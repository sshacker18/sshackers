#!/usr/bin/env python3
"""POCO M2 Pro local diagnostics, conservative cleanup and duplicate review."""
import os, re, time, signal, hashlib, subprocess
from pathlib import Path
from collections import defaultdict

HOME = Path.home()
SHARED = Path("/storage/emulated/0")
REPORTS = HOME / "phone-master-reports"
REPORTS.mkdir(parents=True, exist_ok=True)
PROTECTED_TERMS = ("passport", "aadhaar", "aadhar", "pan card", "payslip",
                   "pay slip", "resume", "medical", "bank", "keystore",
                   "signing", "private key", "id_rsa")
PROTECTED_EXTS = {".jks", ".keystore", ".pem", ".p12", ".pfx", ".key"}
SKIP_DIRS = {"Android", ".thumbnails", ".Trash", ".trash"}

def command(cmd, timeout=12):
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           text=True, timeout=timeout)
        return p.stdout.strip() or "(no output)"
    except Exception as exc:
        return f"(unavailable: {exc})"

def save_report(name, body):
    out = REPORTS / f"{name}-{time.strftime('%Y%m%d-%H%M%S')}.txt"
    out.write_text(body + "\n", errors="replace")
    print(f"\nSaved report: {out}")

def diagnostics():
    sections = []
    def add(title, value): sections.append(f"=== {title} ===\n{value}")
    add("TIME / DEVICE", command(["date"]) + "\n" +
        command(["sh", "-c", "getprop ro.product.model; getprop ro.product.device; getprop ro.build.display.id; uname -a"]))
    add("MEMORY", command(["sh", "-c", "grep -E 'MemTotal|MemAvailable|Cached|SwapTotal|SwapFree' /proc/meminfo"]))
    add("CPU FREQUENCY LIMITS", command(["sh", "-c",
        "for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_{min,max}_freq; do [ -r \"$f\" ] && echo \"$f: $(cat \"$f\")\"; done"]))
    add("CPU FREQUENCIES / GOVERNORS", command(["sh", "-c",
        "for f in /sys/devices/system/cpu/cpu[0-7]/cpufreq/scaling_cur_freq /sys/devices/system/cpu/cpu[0-7]/cpufreq/scaling_governor; do [ -r \"$f\" ] && echo \"$f: $(cat \"$f\")\"; done"]))
    add("TOP SNAPSHOT", command(["sh", "-c", "top -b -n 1 2>&1 | head -n 45"]))
    add("PROCESSES", command(["sh", "-c", "ps -A 2>&1 | head -n 100"]))
    add("THERMAL SENSORS", command(["sh", "-c",
        "for d in /sys/class/thermal/thermal_zone*; do [ -r \"$d/temp\" ] || continue; t=unknown; [ -r \"$d/type\" ] && t=$(cat \"$d/type\"); echo \"${d##*thermal_zone} $t $(cat \"$d/temp\")\"; done"]))
    add("STORAGE", command(["df", "-h", str(SHARED)]))
    add("SWAP (may be restricted)", command(["cat", "/proc/swaps"]))
    add("ADB / ROOT STATUS", command(["sh", "-c", "getprop init.svc.adbd; getprop service.adb.tcp.port; su -c id 2>&1"]))
    report = "\n\n".join(sections)
    print(report)
    save_report("diagnostics", report)

def cleanup_audit():
    roots = [HOME / ".cache", HOME / "tmp", Path(os.environ.get("TMPDIR", str(HOME / "tmp")))]
    roots = list(dict.fromkeys(roots))
    cutoff = time.time() - 7 * 86400
    rows, total = [], 0
    for base in roots:
        if not base.is_dir() or base.is_symlink(): continue
        for root, dirs, files in os.walk(base, followlinks=False):
            dirs[:] = [d for d in dirs if not (Path(root) / d).is_symlink()]
            for name in files:
                p = Path(root) / name
                try:
                    if p.is_symlink() or not p.is_file(): continue
                    st = p.stat()
                    if st.st_mtime < cutoff:
                        rows.append((p, st.st_size, st.st_mtime))
                        total += st.st_size
                except OSError: pass
    rows.sort(key=lambda x: x[2])
    lines = [f"Old files (>7 days) in Termux cache/scratch only: {len(rows)}",
             f"Potential space: {total / (1024**2):.1f} MiB",
             "Nothing is deleted without a separate explicit confirmation."]
    lines += [f"{p} | {size} bytes | age {int((time.time()-mtime)/86400)} days" for p,size,mtime in rows]
    text = "\n".join(lines)
    print(text[:18000])
    save_report("cleanup-audit", text)
    if not rows: return
    if input("\nDelete these listed Termux cache/scratch files older than 7 days? Type DELETE: ") != "DELETE":
        print("Cancelled; no files deleted.")
        return
    deleted = 0
    allowed = [p.resolve() for p in roots if p.is_dir()]
    for p, _, _ in rows:
        try:
            resolved = p.resolve()
            if any(resolved == base or base in resolved.parents for base in allowed):
                resolved.unlink()
                deleted += 1
        except OSError as exc:
            print(f"Skipped {p}: {exc}")
    print(f"Deleted {deleted} old files from Termux cache/scratch only.")

def stop_termux_process():
    print(command(["ps", "-u", str(os.getuid()), "-o", "pid,comm,args"]))
    raw = input("PID to send SIGTERM (blank cancels): ").strip()
    if not raw.isdigit(): print("Cancelled."); return
    pid = int(raw)
    if pid <= 1 or pid == os.getpid():
        print("Refusing unsafe PID."); return
    try:
        status = Path(f"/proc/{pid}/status").read_text()
        uidline = next(x for x in status.splitlines() if x.startswith("Uid:"))
        if int(uidline.split()[1]) != os.getuid():
            print("Refusing: process isn't owned by this Termux UID."); return
        cmdline = Path(f"/proc/{pid}/cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")
        print(f"Target PID {pid}: {cmdline[:300]}")
        if input("Send SIGTERM to this Termux-owned process? Type TERM: ") == "TERM":
            os.kill(pid, signal.SIGTERM)
            print("SIGTERM sent. No Android/system process was targeted.")
    except Exception as exc: print(f"Could not safely stop process: {exc}")

def protected(p):
    n = p.name.lower()
    return p.suffix.lower() in PROTECTED_EXTS or any(x in n for x in PROTECTED_TERMS)

def normalized(name):
    stem, ext = os.path.splitext(name.lower())
    stem = re.sub(r"\s*(?:\(\s*(?:copy\s*)?\d+\s*\)|\[\s*\d+\s*\]|[-_]copy(?:[-_ ]?\d+)?)\s*$", "", stem)
    stem = re.sub(r"\s+copy\s*\d*\s*$", "", stem)
    stem = re.sub(r"\s+", " ", stem).strip(" ._-;()")
    return stem + ext

def digest(p):
    h = hashlib.sha256()
    with p.open("rb") as f:
        for block in iter(lambda: f.read(1024*1024), b""): h.update(block)
    return h.hexdigest()

def scan_files():
    if not SHARED.is_dir():
        print("Shared storage isn't accessible; check Android storage permission."); return
    print("Scanning shared storage (excluding Android private/app data and cache folders). This can take a while.")
    sizes, names = defaultdict(list), defaultdict(list)
    errors = 0
    for root, dirs, files in os.walk(SHARED, followlinks=False):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not (Path(root)/d).is_symlink()]
        for name in files:
            p = Path(root)/name
            try:
                if p.is_symlink() or not p.is_file(): continue
                st = p.stat()
                if st.st_size <= 0: continue
                sizes[st.st_size].append(p)
                names[normalized(name)].append(p)
            except OSError: errors += 1
    exact = defaultdict(list)
    for size, paths in sizes.items():
        if len(paths) < 2: continue
        for p in paths:
            try: exact[(size, digest(p))].append(p)
            except OSError: errors += 1
    groups = [sorted(g, key=lambda p: (protected(p), len(str(p)), str(p)))
              for g in exact.values() if len(g) > 1]
    similar = [sorted(g) for g in names.values() if len(g) > 1]
    out = ["EXACT DUPLICATES (same bytes; SHA-256 verified)"]
    for i,g in enumerate(groups,1):
        out.append(f"\nGROUP {i}:")
        for p in g:
            try: size=p.stat().st_size
            except OSError: size=0
            out.append(f"  {p} | {size} bytes" + (" | protected name" if protected(p) else ""))
    out.append("\nSIMILAR-NAME CANDIDATES (names alone do NOT prove duplicates)")
    for g in similar:
        out.append("  GROUP:")
        out.extend(f"    {p}" for p in g)
    out.append(f"\nRead errors: {errors}")
    report = "\n".join(out)
    print(report[:26000])
    save_report("duplicate-audit", report)
    for g in groups:
        eligible = [p for p in g if not protected(p)]
        if len(eligible) < 2: continue
        print("\nVerified identical group:")
        for i,p in enumerate(g,1): print(f" {i}. {p}" + (" [protected]" if protected(p) else ""))
        if input("Review this group for duplicate removal? [y/N] ").lower() != "y": continue
        keep = input("Number to KEEP (blank cancels): ").strip()
        if not keep.isdigit() or not (1 <= int(keep) <= len(g)):
            print("Group skipped."); continue
        keeper = g[int(keep)-1]
        if protected(keeper):
            print("Protected file selected as keeper; group skipped to avoid risk."); continue
        for p in g:
            if p == keeper or protected(p): continue
            if input(f"Delete this byte-identical duplicate?\n{p}\nType DELETE: ") == "DELETE":
                try: p.unlink(); print("Deleted.")
                except OSError as exc: print(f"Could not delete: {exc}")
    print("Similar-name files are report-only; they are never deleted based on name alone.")

def menu():
    while True:
        print("""
======= POCO PHONE MASTER =======
1. Diagnose CPU/RAM/swap/thermal/process/storage/ADB
2. Audit old Termux temporary/cache files; optional confirmed cleanup
3. Inspect and SIGTERM a Termux-owned process
4. Scan duplicate files/photos/downloads; review exact duplicates
5. List saved reports
6. Exit
=================================
""")
        choice = input("Choose 1-6: ").strip()
        if choice == "1": diagnostics()
        elif choice == "2": cleanup_audit()
        elif choice == "3": stop_termux_process()
        elif choice == "4": scan_files()
        elif choice == "5": print(command(["ls", "-lh", str(REPORTS)]))
        elif choice == "6": break
        else: print("Choose 1-6.")

if __name__ == "__main__":
    menu()
