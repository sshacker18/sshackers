# POCO Health & Charging Audit

A read-only Termux audit for POCO M2 Pro / LineageOS. It does not require root or ADB and does not change Android settings, CPU governors, thermal limits, charging controls, kernel partitions, or running processes.

## Run
From the repository branch:

```bash
bash android/PhoneMaster/device_health_audit.sh
```

Reports are saved to `~/phone-health-reports/`.

## What it captures
- Android `dumpsys battery` view.
- Readable `/sys/class/power_supply` properties (status, online, capacity, voltage, current, temperature, health and cycle data where exposed).
- USB/Type-C role clues if the kernel exposes them.
- Thermal, memory, storage, CPU governor/frequency and process snapshots.
- Six read-only charging samples spaced 10 seconds apart.

## Charging fault limits
Software telemetry can show whether Android detects a charger and what the battery driver reports. It cannot identify a particular wire, solder joint, port pin, charging IC or board trace. If pressure on the phone's back makes charging start, this is a strong reason to have the hardware inspected rather than trying software fixes. Do not keep pressing/bending the phone to reproduce the fault. Stop charging if it heats abnormally, swells, smells unusual, or behaves dangerously.

Likely technician inspection order: known-good charger/cable; USB-C port debris/damage and connector solder joints; charging sub-board; interconnect flex and both ends; battery connector; battery condition; then charging/power-management circuitry. This is a troubleshooting order, not a remote diagnosis.

## Performance strategy
This branch starts with measurement rather than aggressive "RAM booster" tweaks. Android already manages memory and background work; indiscriminate task killing, clearing app caches repeatedly, forcing CPU governors, disabling thermal controls, or applying random build.prop/kernel tweaks can worsen smoothness, stability, heat and battery life. Use the report to identify a real bottleneck before changing settings.


## Battery Flow

`battery_flow.sh` is a separate read-only battery audit. It attempts to collect Android battery service state, readable power-supply telemetry, `dumpsys batterystats` output, third-party package inventory, display/power clues, network-interface counters, and a process snapshot. It saves its report to `~/phone-battery-reports/` and prints safe, conditional recommendations. The Phone Master end-to-end workflow now invokes this Battery Flow after diagnostics, cleanup, process inventory, and duplicate scanning.

No global battery settings or per-app restrictions are changed automatically. Termux is not the privileged Android shell, and broad app restrictions can break notifications, background sync, alarms, or messaging. Use Android Settings > Battery > Battery usage to cross-check any app-level clues and apply restrictions selectively.
