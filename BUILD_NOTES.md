# Lumia 800 Android bring-up build notes

## Device tree

Current target values:

```make
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := scorpion
TARGET_BOARD_PLATFORM := msm7x30
TARGET_BOOTLOADER_BOARD_NAME := msm8x55
```

Boot image values:

```make
BOARD_KERNEL_BASE := 0x00200000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_TAGS_OFFSET := 0x00000100
BOARD_KERNEL_PAGESIZE := 2048
```

Current command line:

```text
androidboot.hardware=lumia800 androidboot.console=ttyMSM1 console=ttyMSM1,115200n8 loglevel=8 printk.time=1
```

The device tree currently uses a prebuilt kernel and marks virtual image sizes as **do not flash to current Lumia partitions**.

## ADB / FunctionFS

`init.lumia800.rc` creates and mounts:

```text
/dev/usb-ffs/adb
```

and starts `adbd`.

The kernel has:

```text
CONFIG_USB_GADGET=y
CONFIG_USB_GADGET_MSM_72K=y
CONFIG_USB_FUNCTIONFS=y
CONFIG_USB_FUNCTIONFS_GENERIC=y
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
```

So the userspace and kernel configuration are conceptually aligned around FunctionFS ADB.

## Kernel

Kernel release:

```text
3.0.1+
```

Generated build metadata:

```text
#4 PREEMPT Fri Aug 28 21:21:26 UTC 2026
arm
gcc version 4.3.3 (Sourcery G++ Lite 2009q1-203)
```

The config enables Qualcomm MSM7x30/MSM8x55-era board support rather than a dedicated `MACH_LUMIA800` machine definition. The current source still contains the generic Qualcomm `MACHINE_START` entries such as MSM7X30 SURF/FFA/FLUID and MSM8X55 SURF/FFA.

That means hardware-specific Sea Ray work should not be considered complete just because the kernel builds.

## zImage audit

Device-tree prebuilt:

```text
size:   4,105,644
sha256: 03afa698eab4ad9b40071b6927c2fdbf53eb866397794c3841bf55ee2d7bcf4e
```

Kernel-v0.5 build output:

```text
size:   4,105,708
sha256: 453c46beb9963c4dbc82dcf2c04acc965ad50284d9a2ded68bd1d5d2f555ed47
```

They differ. Before producing the next `boot.img`, explicitly select the intended kernel and synchronize the device tree.

## Toolchain

Outer ZIP:

```text
5ec49996567803a790043f8a408c2dc2183a3d53154cb04f7d86bb7154484da0  arm-2009q1-toolchain(3).zip
```

Inner tarball:

```text
0004b59223f8151d1af211894e5c76c142e4c0e4529b531bf8f5565ec7f08ae6  arm-2009q1-203-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
```

Compiler family:

```text
Sourcery G++ Lite 2009q1-203
GCC 4.3.3
arm-none-linux-gnueabi-
```

The package name indicates an i686 Linux host build. Use it in a compatible Linux environment/container rather than assuming it is a native macOS executable.

## Current blocker hierarchy

1. Verify the experimental Fastboot loader enumerates reliably.
2. Verify `getvar` responses.
3. Determine whether the current loader has a usable `boot` command; current binary strings only clearly expose `getvar:`, `download:` and `reboot`.
4. Synchronize the chosen kernel zImage with `device/nokia/lumia800/prebuilt/zImage`.
5. Build a known, hash-recorded boot image.
6. Obtain early diagnostics through serial/USB/ADB before adding higher-level hardware support.
