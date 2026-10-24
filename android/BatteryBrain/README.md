# Battery Brain for POCO M2 Pro / LineageOS

Battery Brain is a small native Android collector plus an offline Python report tool. It avoids Termux:API and does not require ADB pairing or root.

## What it collects

Android's public `ACTION_BATTERY_CHANGED` broadcast supplies charge level, plugged state, status, health, temperature and voltage. `BatteryManager` current and charge-counter values are recorded when the kernel exposes them; they may be unavailable.

The app stores a local CSV in its private app storage. The user can manually capture a reading, enable WorkManager sampling (minimum interval 15 minutes), stop sampling, and export the CSV using Android's document picker. Android may defer periodic work, particularly during Doze or battery restrictions.

## Build

Open this directory in Android Studio and build the debug variant, or use the repo workflow **Battery Brain Android CI**. The CI artifact is named `battery-brain-debug-apk`. Install the debug APK only after reviewing the build and trusting the source.

Local build:
```sh
gradle assembleDebug
```

Minimum Android version: API 26. Target SDK: 35.

## Python analysis in Termux

Copy the exported CSV to a readable location, then run:
```sh
python tools/battery_analyzer.py /storage/emulated/0/Download/battery-history.csv --out battery-report.txt
```

The analyzer uses only Python's standard library, works offline, calculates approximate unplugged discharge rates, flags sampled heat and unusual intervals, and prints conservative suggestions. It does not modify settings or terminate processes.

## Safe optimization principles

1. Collect a baseline through a normal day before changing settings.
2. Compare similarly used days and change one setting at a time.
3. Use Android Settings → Battery to identify app-level usage; this collector cannot obtain privileged per-app power attribution from a normal app.
4. If the device reports high battery temperature, reduce heavy usage and charging heat and let it cool naturally.
5. Do not disable Android system services or force-kill apps on the theory that this must save battery.

Battery percentage is coarse, current measurements can be noisy, and the OS can defer background work. Treat the report as an evidence-based estimate, not a laboratory battery health test.
