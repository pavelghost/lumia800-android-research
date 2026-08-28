# Nokia Lumia 800 (Sea Ray): WP7 ↔ experimental read-only Fastboot

> **Research notes / recovery guide for Nokia Lumia 800 (MSM8255 / Sea Ray).**
>
> This document describes a workflow I verified on my own Lumia 800 while experimenting with an LK-derived USB/Fastboot bring-up loader. It is not a universal flashing guide. Writing the wrong file or selecting the wrong disk can brick a device or damage another disk connected to the Mac.

## What I verified

I have three independent artifacts from the experiment:

| Artifact | Size | SHA-256 | Meaning |
|---|---:|---|---|
| `Lumia800-EMMCBOOT-stock-v10-20260828-103953(1).MBN` | 806,992 B | `bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf` | Stock Windows Phone 7 EMMCBOOT backup |
| `Lumia800-experimental-EMMCBOOT-20260828-100931.MBN` | 21,824 B | `7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d` | Experimental Lumia 800 USB-only / read-only Fastboot loader |
| `lumia800-fat(2).zip` | 20,685,803 B | `04694c44046ed9b4be70eefb7f5e5b350ea211824f18b9183f80c4056f09a65a` | Backup of the 150 MB FAT16 boot volume |

The ZIP contains one image:

```text
lumia800-fat.img
```

Its size is:

```text
153,600,000 bytes
```

The FAT16 image contains:

```text
IMAGE2/amss.mbn
IMAGE2/adsp.mbn
IMAGE2/emmcboot.mbn
```

The `IMAGE2/emmcboot.mbn` inside this FAT image is byte-for-byte the same stock EMMCBOOT backup:

```text
SHA-256:
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

This gives me two matching copies of the original WP7 bootloader.

## What the experimental EMMCBOOT is

Strings found directly in my experimental binary include:

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

This confirms that this particular build is not the stock WP7 loader. It is a Lumia 800-specific experimental loader designed to bring up USB/Fastboot while deliberately avoiding normal eMMC/board initialization and forcing a read-only Fastboot-oriented mode.

Its exact SHA-256 is:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

## Important distinction

Earlier experiments also used an `ENTRY PROBE` file with SHA-256:

```text
135d642385ff44fa93ce5b3368c25f6ae55eb9bab2987f76271f172e4da363aa
```

That is **not** the same file as:

```text
Lumia800-experimental-EMMCBOOT-20260828-100931.MBN
```

Do not mix these two builds in notes or restore instructions.

---

# Returning from stock WP7 to my experimental Fastboot loader

If the phone currently boots normal Windows Phone 7, `fastboot devices` will not magically detect it. The stock `EMMCBOOT.MBN` does not provide Android Fastboot.

To get the experimental Fastboot interface again, I replace only `IMAGE2/EMMCBOOT.MBN` with my verified experimental file.

## 1. Expose the Lumia boot FAT volume

Put the Lumia into the same diagnostics / storage mode that exposes the ~150 MB boot volume to macOS.

The historical `lk_umia` workflow uses Lumia diagnostics mode and then replaces `image2/emmcboot.mbn`.

On my Mac I first identify the Lumia disk:

```bash
diskutil list
```

I expect an external Lumia disk with the familiar partition layout. The disk number is not fixed.

For example, it may be:

```text
/dev/disk6
```

but **never assume `/dev/disk6` without checking**.

## 2. Mount the boot FAT partition

Example only, if the Lumia really is `/dev/disk6` and the FAT partition is `s3`:

```bash
diskutil mount /dev/disk6s3
diskutil info /dev/disk6s3 | grep -E "Device Node|Volume Name|Mount Point"
```

My volume normally appears as:

```text
/Volumes/NO NAME
```

Verify that this exists:

```bash
ls -la "/Volumes/NO NAME/IMAGE2"
```

Expected important files:

```text
AMSS.MBN
ADSP.MBN
EMMCBOOT.MBN
```

## 3. Confirm that WP7 stock is currently installed

Before replacing anything:

```bash
shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

For my known stock file the result is:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

Also check the experimental file on the Mac:

```bash
shasum -a 256 "$HOME/Desktop/Lumia800-experimental-EMMCBOOT-20260828-100931.MBN"
```

Expected:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

If either value differs, stop.

## 4. Make one more stock backup

```bash
cp -p "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN" \
"$HOME/Desktop/Lumia800-EMMCBOOT-stock-before-fastboot.MBN"

shasum -a 256 "$HOME/Desktop/Lumia800-EMMCBOOT-stock-before-fastboot.MBN"
```

It should again be:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

## 5. Install the experimental read-only Fastboot EMMCBOOT

Only after all hashes are verified:

```bash
cp -f "$HOME/Desktop/Lumia800-experimental-EMMCBOOT-20260828-100931.MBN" \
"/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"

sync
```

Verify what is now physically present on the Lumia:

```bash
shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

It must now be:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

## 6. Safely detach

Again, replace `disk6` with the disk number actually shown on your Mac:

```bash
diskutil unmount /dev/disk6s3
diskutil eject /dev/disk6
```

Disconnect USB.

Power-cycle the phone using the same non-destructive procedure used during the experiment. Avoid factory-reset key combinations.

## 7. Test USB Fastboot

Reconnect the Lumia to the Mac and run:

```bash
fastboot devices
```

If Android Platform Tools are installed correctly and the experimental loader enumerates successfully, the device should appear in the Fastboot list.

Then use only harmless identification commands first:

```bash
fastboot getvar version
fastboot getvar product
fastboot getvar serialno
```

The experimental binary contains the product marker:

```text
LUMIA800_FASTBOOT
```

so `getvar` is one of the first things worth testing.

---

# Do not flash Android yet

For this bring-up stage I do **not** use:

```bash
fastboot flash boot boot.img
```

I also do not assume that every standard Fastboot command is implemented.

The current experimental binary clearly contains support strings for:

```text
getvar
download
reboot
```

and advertises itself as a read-only Fastboot bring-up build.

That proves that the goal of this build is safe USB/Fastboot communication, but it does **not by itself prove** that `fastboot boot boot.img` is already fully implemented and working.

The correct development order is:

```text
1. Make Fastboot enumerate
2. fastboot devices
3. fastboot getvar ...
4. Verify downloads
5. Verify the temporary boot command in the loader source/build
6. Only then attempt fastboot boot boot.img
```

---

# Restoring Windows Phone 7

To return to WP7, mount the same boot FAT partition and restore the verified stock file:

```bash
cp -p "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN" \
"$HOME/Desktop/Lumia800-experimental-current-backup.MBN"

cp -f "$HOME/Desktop/Lumia800-EMMCBOOT-stock-v10-20260828-103953.MBN" \
"/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"

sync
```

Verify:

```bash
shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

Expected stock SHA-256:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

Then safely unmount/eject the Lumia, disconnect USB and boot normally.

Replacing only the saved `IMAGE2/EMMCBOOT.MBN` does not itself format the Lumia user-data partitions.

---

# My current boot-chain experiment

The development idea is:

```text
Stock Lumia 800 / WP7
        │
        ├── 150 MB FAT boot volume
        │       └── IMAGE2/EMMCBOOT.MBN
        │
        ├── stock EMMCBOOT
        │       └── Windows Phone 7
        │
        └── experimental EMMCBOOT
                └── Lumia 800 USB-only LK bring-up
                        └── read-only Fastboot
                                ├── devices
                                ├── getvar
                                ├── download
                                └── future temporary Android boot testing
```

## Why this matters

The key achievement is not simply “Android boots”.

The important part of the work is that I now have a repeatable recovery path:

```text
WP7 stock EMMCBOOT
        ↓
experimental EMMCBOOT
        ↓
Fastboot bring-up/testing
        ↓
restore verified stock EMMCBOOT
        ↓
WP7 boots again
```

That makes low-level Lumia 800 development much less blind than repeatedly writing permanent Android boot images without a known recovery path.

---

# Verified hashes

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf  Lumia800-EMMCBOOT-stock-v10-20260828-103953(1).MBN
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d  Lumia800-experimental-EMMCBOOT-20260828-100931.MBN
04694c44046ed9b4be70eefb7f5e5b350ea211824f18b9183f80c4056f09a65a  lumia800-fat(2).zip
```

Inside `lumia800-fat.img`:

```text
eeb1752559096c6315c115dff517666a5e406c67d306357708bca68a15e1b851  IMAGE2/amss.mbn
1d2ea08efdde127aa5dd8b10ea4886c97b3e625ff936ee6a97bdcf1a7a727abb  IMAGE2/adsp.mbn
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf  IMAGE2/emmcboot.mbn
```

---

# External reference

The historical `fredldotme/lk_umia` project describes the same general workflow:

1. enter Lumia diagnostics mode;
2. back up the ~150 MB partition;
3. replace `image2/emmcboot.mbn` with LK;
4. unmount;
5. boot the phone;
6. test with `fastboot devices` and `fastboot getvar version`.

My current experimental file is a custom Lumia 800 / `searay800` bring-up build and should therefore be documented separately from the old generic build.

---

## Disclaimer

This repository documents experimental reverse-engineering / operating-system porting on obsolete personal hardware.

Always keep multiple verified backups of the original boot files. Never hard-code a `/dev/diskX` value. Never write to a disk until its identity and hashes have been confirmed.
