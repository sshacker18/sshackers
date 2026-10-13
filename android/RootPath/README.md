# RootPath

A safety-first Android rooting preparation toolkit.

## Current scope

`rootpath-preflight.sh` collects Android build/device properties, boot-state properties, architecture, storage, and root-manager package indicators into a timestamped report.

**It does not root the device.** A shell script running inside an unprivileged Termux session cannot grant itself Android UID 0 or safely flash a boot/kernel/recovery partition. Real root installation requires a compatible, verified image and a device-specific installation path.

## Run on Termux

From the repository directory:

```bash
bash android/RootPath/rootpath-preflight.sh
```

The report is saved in Termux's home directory. The script is read-only and does not download files, change settings, patch images, or flash partitions.

## Safety gates before any root installation

1. Confirm the exact hardware variant and active ROM package.
2. Resolve contradictory device properties before choosing an image.
3. Verify the bootloader state using an appropriate device-specific method; system properties alone are not conclusive.
4. Obtain the boot/init_boot/recovery image from the exact installed ROM build.
5. Follow the selected root project's official, device-compatible instructions and have a recovery plan.

Never flash an image from a different device or build. This repository is an experimental helper, not a replacement root framework or a guarantee of compatibility.
