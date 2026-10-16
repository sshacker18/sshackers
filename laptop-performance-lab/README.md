# Laptop Performance Pilot

A Windows CMD-first performance toolkit for a low-memory laptop. This is the higher priority project; the Playwright demo is optional.

## Design goals

- Measure before changing anything.
- Identify pressure points: available RAM, top working sets, Chrome aggregate working set, CPU details, startup entries, and disk capacity.
- Open supported Windows and Chrome settings instead of editing the registry or blindly disabling services.
- Run with built-in Windows CMD and PowerShell. No Python required for the audit toolkit.
- Save timestamped reports locally under \`logs\`; reports are ignored by Git.

## Run

From CMD:

\`\`\`cmd
run-lab.cmd
\`\`\`

Choose **1** to create a diagnostic report, **2** to open Chrome Memory Saver settings, **3** to open Windows Startup Apps, **4** to open Task Manager and Resource Monitor, or **5** to open Windows Storage settings.

## Recommended first tuning pass

1. Save a baseline report with your normal workload open.
2. Open Windows Settings > Apps > Startup. Disable only apps you recognize and do not need to start automatically. Avoid disabling security, touchpad, audio, graphics, or device drivers.
3. In Chrome, visit \`chrome://settings/performance\` and enable Memory Saver. Start at Balanced; try Maximum only if you can accept inactive tabs reloading more often.
4. Close tabs/extensions you do not need. Chrome's multiple processes are normal and are not proof of rogue processes.
5. Re-run a report after using the same workload for a comparable period. Compare trends rather than treating a single free-memory number as the entire performance story.

## Safety boundaries

- Diagnostics do not stop processes or change system settings.
- The toolkit does not disable Defender, terminate Windows services, edit the registry, change the page file, modify the power plan, overclock the CPU, or change BIOS.
- It does not promise more physical RAM or guaranteed speed increases.
- Working sets can include shared pages. Summing process working sets is a useful rough diagnostic, not exact private-memory attribution.
- Storage cleanup is left to Windows Storage settings so the user can review categories before deletion.
- Windows 10 reached end of standard support on 14 October 2025. Consider an eligible upgrade or supported OS plan; performance tuning is not a substitute for security updates.

## Baseline from the user's own console output

The laptop reported 4,107,668 KB visible RAM, with free physical memory varying from about 720 MB to 968 MB across different snapshots. Chrome's combined reported working set was about 1,296 MB in one capture. These values change with workload and background activity.
