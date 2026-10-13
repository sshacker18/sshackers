# POCO Phone Master (Termux)

Local-first menu for the POCO M2 Pro / Android. Runs from Termux, optionally inside tmux. It does not require root or ADB.

## Features
1. Read-only diagnostics: memory/swap, CPU frequencies/governors, thermal sensor labels, process snapshot, storage, ADB/root status.
2. Audit old files in Termux-owned cache/scratch locations; deletion requires typing DELETE.
3. Inspect processes owned by the Termux UID and optionally send SIGTERM after confirmation. It refuses to signal processes owned by another UID.
4. Scan shared storage for byte-identical duplicates using file size plus SHA-256. Android private app data and Android/OBB are excluded. Similar-name candidates are report-only; names alone never prove duplicate content. APK copies can be identified as identical content and reviewed interactively.
5. Reports are saved to ~/phone-master-reports.

The tool does not change CPU governors, clock limits, kernel/boot partitions, Android settings, or ADB configuration. It does not wipe app data. Cleanup and duplicate removal require explicit interactive confirmation; inspect reports before confirming. Access restrictions may prevent scanning some Android folders.

## Launch
From a clone of this branch:
```bash
bash android/PhoneMaster/launch.sh
```

To detach from tmux: Ctrl+B, then D. Reopen with:
```bash
tmux attach -t phone-master
```

Reports: `~/phone-master-reports/`
