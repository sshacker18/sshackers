# Chrome RAM Lab (Windows CMD)

A small, diagnostic-first toolkit for Windows 10/11 laptops with limited RAM. Designed for the user's Windows 10 build 19045 and approximately 4 GB RAM.

## Goals

1. Record a repeatable baseline before and after browser changes.
2. Report total/free physical memory and the largest process working sets.
3. Report Chrome's combined working set rather than treating each Chrome process as a separate problem.
4. Open Chrome's built-in Performance settings and Task Manager.
5. Require no Python, Bash, Node.js, or administrator privileges.

The entry points are Windows \`.cmd\` scripts. The snapshot uses Windows' built-in PowerShell for process sorting and summary calculations.

## Safe first experiment

1. Run \`check-tools.cmd\` to see whether Git, Python, and Chrome are detectable. Python is optional and is not used by this project.
2. Run \`ram-snapshot.cmd\` with your normal apps open. Save the reported log path.
3. Run \`open-chrome-performance.cmd\` and set **Memory Saver** to **Balanced** first. Google's documentation describes Balanced as the recommended setting. If many inactive tabs still strain the machine and reloads are acceptable, test Maximum instead.
4. Use Chrome's Task Manager to identify tabs/extensions that consume unusual amounts of memory. In Chrome, open \`chrome://task-manager\`, sort by memory, and close only items you recognize and do not need.
5. Capture another snapshot with \`ram-snapshot.cmd\`. Compare the free-memory reading and Chrome combined working set, while keeping your workload as similar as possible.

Chrome Settings: \`chrome://settings/performance\`  
Chrome Task Manager: \`chrome://task-manager\`

## Commands

- \`check-tools.cmd\` — detect Git, optional Python, Chrome path, and memory state.
- \`ram-snapshot.cmd\` — write a timestamped report to \`logs\` and display it.
- \`open-chrome-performance.cmd\` — open Chrome Performance settings without changing them automatically.
- \`run-lab.cmd\` — interactive launcher for the scripts above.

## Install Git if needed

From CMD, first run:

\`\`\`cmd
where git
git --version
\`\`\`

If Git is missing and Windows Package Manager is available:

\`\`\`cmd
winget --version
winget install --id Git.Git -e --source winget
\`\`\`

Close and reopen CMD after installation, then confirm with \`git --version\`. Official download and setup instructions: https://git-scm.com/install/windows

## Clone this branch

\`\`\`cmd
git clone --branch feat/chrome-ram-lab --single-branch https://github.com/sshacker18/sshackers.git
cd sshackers\chrome-ram-lab
run-lab.cmd
\`\`\`

## Safety boundaries

- This toolkit does not kill processes, terminate services, edit the registry, change the page file, disable Defender, or change BIOS/Intel CPU settings.
- It does not claim to increase physical RAM or overclock the processor.
- Logs are local and ignored by Git.
- Working-set sizes are per-process snapshots, not exact private-memory attribution. Windows' available-memory counter, standby cache, compression, and shared pages mean individual process numbers do not add up neatly to total RAM use.
- For this 4 GB system, the recommended first optimization is Chrome's supported Memory Saver setting plus identifying heavy tabs, not blind process termination.

## Current baseline from user-provided console output

- Total visible memory: 4,107,668 KB (approximately 3.92 GiB).
- Free physical memory at the most recent capture: 968,592 KB (approximately 923 MiB).
- Top reported processes included Chrome (461 MB for one process), SearchApp (214 MB), and Microsoft Defender (205 MB).

These are point-in-time observations, not a guarantee of current state or evidence that any process is malicious.
