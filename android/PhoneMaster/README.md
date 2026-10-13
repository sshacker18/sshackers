# POCO Phone Master (Termux)

Two-option menu for the POCO M2 Pro / Android. Runs locally in Termux and optionally inside tmux. No root or ADB required.

## Menu
1. Exit
2. Run end-to-end

The end-to-end run automatically performs all five stages without interactive prompts: (1) CPU/RAM/swap/thermal/process/storage/ADB diagnostics, (2) cleanup of old regular files more than 7 days old in Termux cache/scratch locations, (3) read-only inventory of Termux-owned processes, (4) shared-storage exact-duplicate scan and removal, and (5) saved-report listing. Reports are stored in `~/phone-master-reports`.

## Safety behavior
- Process inventory is read-only. It does not kill an arbitrary process because unattended mode cannot safely infer which PID the user wants terminated.
- Cache cleanup is restricted to Termux cache/scratch paths; it does not clean shared storage or Android app data.
- Duplicate removal requires matching size and SHA-256, rechecks the files immediately before unlinking, keeps one preferred copy, and skips any duplicate group containing a protected filename or extension.
- Similar-name files are report-only and are never deleted based on names alone.
- Android private app data/OBB, Android folders, thumbnails, and trash folders are excluded.
- The tool does not change CPU governors, kernel/boot partitions, Android settings, or ADB configuration.

## Launch
From a clone of this branch:
```bash
bash android/PhoneMaster/launch.sh
```

Detach from tmux with Ctrl+B, then D. Reopen with:
```bash
tmux attach -t phone-master
```

Reports: `~/phone-master-reports/`
