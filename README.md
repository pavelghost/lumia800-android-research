# Nokia Lumia 800 (Sea Ray) — WP7 ↔ experimental Fastboot research

Experimental bring-up notes for **Nokia Lumia 800 / Sea Ray / Qualcomm MSM8255 (msm8x55 family)**.

This repository documents a workflow I reproduced on my own Lumia 800 while researching an LK-derived USB/Fastboot loader and an Android 6 / CyanogenMod 13 bring-up.

> **Warning:** this is low-level bootloader research, not a universal flashing guide. A wrong `/dev/diskX`, a wrong `EMMCBOOT.MBN`, or an interrupted write can make the phone unbootable. Keep multiple verified backups before changing anything.

## Guides

- [`FASTBOOT.md`](FASTBOOT.md) — switch **WP7 → experimental Fastboot**, verify with `fastboot devices`, diagnose USB/Fastboot, and return to WP7.
- [`RESTORE_WP7.md`](RESTORE_WP7.md) — focused stock Windows Phone 7 EMMCBOOT recovery procedure.
- [`BUILD_NOTES.md`](BUILD_NOTES.md) — kernel, toolchain and CM13 device-tree notes.
- [`SHA256SUMS.txt`](SHA256SUMS.txt) — verified research artifact hashes.

---

## What I have actually verified

I can now reproduce the following cycle:

```text
stock Windows Phone 7
        ↓
expose the Lumia boot FAT volume
        ↓
back up IMAGE2/EMMCBOOT.MBN
        ↓
replace it with my experimental USB/Fastboot EMMCBOOT
        ↓
perform Fastboot bring-up tests
        ↓
restore the exact stock EMMCBOOT
        ↓
Windows Phone 7 boots again
```

The important part is the **recovery path**. I am no longer experimenting without a known route back to the original WP7 bootloader.

## Verified artifacts

| Artifact | Size | SHA-256 | Status |
|---|---:|---|---|
| `Lumia800-EMMCBOOT-stock-v10-20260828-103953(1).MBN` | 806,992 B | `bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf` | Verified stock WP7 EMMCBOOT backup |
| `Lumia800-experimental-EMMCBOOT-20260828-100931.MBN` | 21,824 B | `7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d` | Experimental Lumia 800 USB/read-only Fastboot loader |
| `lumia800-fat(2).zip` | 20,685,803 B | `04694c44046ed9b4be70eefb7f5e5b350ea211824f18b9183f80c4056f09a65a` | Backup containing the 153,600,000-byte FAT16 image |
| `arm-2009q1-toolchain(3).zip` | — | `5ec49996567803a790043f8a408c2dc2183a3d53154cb04f7d86bb7154484da0` | Sourcery ARM toolchain package |
| `lumia800-device-tree-audit(3).zip` | — | `d72cdf8977eadbc860719453e7dbef3872ef1143783c7c42f41f0cebafac80d1` | Current CM13 Lumia 800 device-tree snapshot |
| `lumia800-kernel-v0.5-source(4).zip` | — | `2ce8034cfc884d7bbe4c5371559fecc347867427a1f7ac26a394f7cfbcb6be9e` | Current Linux 3.0.1+ kernel source/build snapshot |

The FAT16 backup contains:

```text
IMAGE2/AMSS.MBN      16,711,680 bytes
IMAGE2/ADSP.MBN       5,618,760 bytes
IMAGE2/EMMCBOOT.MBN     806,992 bytes
```

Its internal hashes are recorded in `SHA256SUMS.txt`.

Most importantly, `IMAGE2/EMMCBOOT.MBN` inside the FAT image has exactly the same SHA-256 as my separately saved stock file:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

So I currently have **two matching copies of the original WP7 EMMCBOOT**.

---

# Experimental EMMCBOOT

The experimental 21,824-byte binary is clearly not the Windows Phone loader.

Strings found directly in the file include:

```text
searay800
Lumia 800 USB-only target: skipping eMMC and board init
Lumia 800 bring-up: forcing read-only fastboot
LUMIA800_FASTBOOT
getvar:
download:
reboot
fastboot
```

This is strong evidence that the build was intentionally made for a **Lumia 800 / Sea Ray USB-only Fastboot bring-up** and deliberately avoids normal eMMC initialization.

### Important: `fastboot boot` is not yet verified

At the moment I do **not** claim that this exact experimental binary can already execute:

```bash
fastboot boot boot.img
```

The binary visibly contains command strings for:

```text
getvar
download
reboot
```

but I have not yet verified a `boot` command handler in this exact build.

Therefore the correct order is:

```text
1. USB enumeration
2. fastboot devices
3. fastboot getvar ...
4. download-path testing
5. verify/implement temporary boot command
6. only then test Android boot.img in RAM
```

I intentionally avoid presenting `fastboot flash boot` as part of the bring-up workflow.

---

# Returning from WP7 to the experimental Fastboot loader

If the phone currently runs stock Windows Phone 7, this alone will normally not make it appear in:

```bash
fastboot devices
```

The experimental `EMMCBOOT.MBN` must be active first.

## 1. Identify the Lumia disk on macOS

```bash
diskutil list
```

In one of my sessions the Lumia was `/dev/disk6`, but the number is **not permanent**.

Never copy a `/dev/diskX` value blindly.

## 2. Mount the boot FAT partition

Example only, if the current Lumia really is `disk6` and its FAT partition is `s3`:

```bash
diskutil mount /dev/disk6s3
diskutil info /dev/disk6s3 | grep -E "Device Node|Volume Name|Mount Point"
```

In my setup the mount point was:

```text
/Volumes/NO NAME
```

Check the boot directory:

```bash
ls -la "/Volumes/NO NAME/IMAGE2"
```

## 3. Verify the currently installed stock EMMCBOOT

```bash
shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

My stock value is:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

Verify the experimental file too:

```bash
shasum -a 256 "$HOME/Desktop/Lumia800-experimental-EMMCBOOT-20260828-100931.MBN"
```

Expected for my experimental build:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

If either value is unexpected, stop and investigate before writing.

## 4. Make another stock backup

```bash
cp -p "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN" \
"$HOME/Desktop/Lumia800-EMMCBOOT-stock-before-fastboot.MBN"

shasum -a 256 "$HOME/Desktop/Lumia800-EMMCBOOT-stock-before-fastboot.MBN"
```

## 5. Install the experimental EMMCBOOT

Only after the disk identity and hashes are confirmed:

```bash
cp -f "$HOME/Desktop/Lumia800-experimental-EMMCBOOT-20260828-100931.MBN" \
"/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"

sync
```

Verify the file on the phone:

```bash
shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

Expected:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

## 6. Safely eject

Example only:

```bash
diskutil unmount /dev/disk6s3
diskutil eject /dev/disk6
```

Then disconnect USB and power-cycle the phone without using a factory-reset key combination.

## 7. Test Fastboot

Reconnect USB and start with read-only identification tests:

```bash
fastboot devices
fastboot getvar version
fastboot getvar product
fastboot getvar serialno
```

The historical `fredldotme/lk_umia` project documents the same general Lumia workflow: back up the ~150 MB partition, replace `image2/emmcboot.mbn`, unmount, reboot, then test `fastboot devices` and `fastboot getvar version`.

Reference: https://github.com/fredldotme/lk_umia

---

# Restoring Windows Phone 7

My verified reverse procedure is in [`RESTORE_WP7.md`](RESTORE_WP7.md).

The short version is:

```bash
cp -f "$HOME/Desktop/Lumia800-EMMCBOOT-stock-v10-20260828-103953.MBN" \
"/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
sync
shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

The final SHA-256 must be:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

Replacing only the saved `IMAGE2/EMMCBOOT.MBN` does not itself format the user-data partitions. This assumes the other partitions were not separately damaged or overwritten.

---

# Android / CyanogenMod 13 bring-up tree

My current device tree identifies the target as:

```make
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_VARIANT := scorpion
TARGET_BOARD_PLATFORM := msm7x30
TARGET_BOOTLOADER_BOARD_NAME := msm8x55
```

Boot-image layout currently configured in `BoardConfig.mk`:

```make
BOARD_KERNEL_BASE := 0x00200000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_TAGS_OFFSET := 0x00000100
BOARD_KERNEL_PAGESIZE := 2048
```

Current kernel command line:

```text
androidboot.hardware=lumia800 androidboot.console=ttyMSM1 console=ttyMSM1,115200n8 loglevel=8 printk.time=1
```

The device tree is configured as a **bring-up/debug build**, including:

```text
ro.secure=0
ro.adb.secure=0
ro.debuggable=1
persist.sys.usb.config=adb
```

The root init configuration mounts FunctionFS at:

```text
/dev/usb-ffs/adb
```

and starts `adbd`.

This is intentional: the current bring-up is focused on getting a usable debug channel before trying to make every phone subsystem work.

### About the Android4Lumia `fame` tree

The Android4Lumia `android_device_nokia_fame` repository is useful as a **CM13 Lumia device-tree reference**, but it targets the Lumia 520-series / MSM8227, not the Lumia 800 / MSM8255.

Reference: https://github.com/Android4Lumia/android_device_nokia_fame

So I use it as a structural/reference source, not as a drop-in hardware definition for Sea Ray.

---

# Kernel build that I have

The kernel archive contains a built **Linux 3.0.1+** tree.

Generated build metadata says:

```text
UTS_RELEASE: 3.0.1+
UTS_VERSION: #4 PREEMPT Fri Aug 28 21:21:26 UTC 2026
architecture: arm
compiler: gcc version 4.3.3 (Sourcery G++ Lite 2009q1-203)
```

Relevant configuration includes:

```text
CONFIG_ARCH_MSM=y
CONFIG_ARCH_MSM7X30=y
CONFIG_ARCH_MSM_SCORPION=y
CONFIG_MACH_MSM8X55_SURF=y
CONFIG_MACH_MSM8X55_FFA=y
CONFIG_PREEMPT=y
CONFIG_AEABI=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_USB_GADGET=y
CONFIG_USB_GADGET_MSM_72K=y
CONFIG_USB_FUNCTIONFS=y
CONFIG_USB_FUNCTIONFS_GENERIC=y
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
```

This matches the current plan to use a legacy Qualcomm MSM7x30/msm8x55 kernel with Android/FunctionFS support enabled.

---

# Toolchain

The provided toolchain ZIP contains:

```text
arm-2009q1-203-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
```

The inner tarball SHA-256 is:

```text
0004b59223f8151d1af211894e5c76c142e4c0e4529b531bf8f5565ec7f08ae6
```

It contains Sourcery GCC **4.3.3**, which is also exactly what the kernel's generated `compile.h` reports.

The historical `lk_umia` README uses the same Sourcery 2009q1-203 toolchain family.

Because this package is the old **i686-pc-linux-gnu** build, I treat it as a Linux build toolchain rather than a native modern macOS compiler.

---

# Important zImage mismatch found during audit

The current device-tree archive contains:

```text
device/nokia/lumia800/prebuilt/zImage
```

Size:

```text
4,105,644 bytes
```

SHA-256:

```text
03afa698eab4ad9b40071b6927c2fdbf53eb866397794c3841bf55ee2d7bcf4e
```

But the kernel-v0.5 archive contains a different built image:

```text
kernel-lumia800-v0.5/arch/arm/boot/zImage
```

Size:

```text
4,105,708 bytes
```

SHA-256:

```text
453c46beb9963c4dbc82dcf2c04acc965ad50284d9a2ded68bd1d5d2f555ed47
```

Therefore these two files must **not** be assumed to be the same kernel.

Before the next Android boot-image build I need to deliberately choose which zImage is authoritative and copy that exact build into the device tree.

This is one of the most important findings from the current audit.

---

# Current project status

### Verified

- stock WP7 EMMCBOOT backed up;
- second matching stock EMMCBOOT exists inside the FAT16 backup;
- experimental Lumia 800 USB/read-only Fastboot EMMCBOOT identified;
- safe stock ↔ experimental EMMCBOOT replacement workflow established;
- WP7 recovery path established;
- Linux 3.0.1+ kernel has been compiled with Sourcery GCC 4.3.3;
- CM13 Lumia 800 device tree exists;
- FunctionFS + ADB bring-up configuration exists;
- kernel and device-tree build artifacts have been audited by hash.

### Not yet claimed as working

- permanent Android installation;
- fully working display/touch/modem/audio/camera;
- a verified `fastboot boot boot.img` handler in the current 21,824-byte experimental EMMCBOOT;
- a final synchronized kernel/device-tree `zImage`;
- a production-ready Lumia 800 Android ROM.

---

# Next technical milestone

The safest next milestone is not flashing Android permanently.

It is:

```text
experimental EMMCBOOT
        ↓
USB Fastboot enumerates
        ↓
fastboot devices
        ↓
fastboot getvar works
        ↓
verify/implement boot command
        ↓
load a known boot.img into RAM
        ↓
obtain early kernel/serial/ADB diagnostics
```

Only after this path is reliable does it make sense to continue hardware bring-up.

---

# Historical ENTRY PROBE note

One earlier experiment referenced an `ENTRY PROBE` EMMCBOOT with SHA-256:

```text
135d642385ff44fa93ce5b3368c25f6ae55eb9bab2987f76271f172e4da363aa
```

That binary is **not included in the artifact set audited for this revision**, so I keep it separate from the verified 21,824-byte experimental Fastboot build:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

They must not be confused.

---

# Credits / references

- `fredldotme/lk_umia` — historical LK Lumia bootloader workflow: https://github.com/fredldotme/lk_umia
- Android4Lumia `android_device_nokia_fame` — CM13 Lumia device-tree reference: https://github.com/Android4Lumia/android_device_nokia_fame

## Disclaimer

This repository documents reverse-engineering and operating-system porting experiments on obsolete personal hardware. Verify every hash and disk identifier yourself. Do not assume that files from one Lumia are safe for another device.
