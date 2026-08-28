# Restore stock Windows Phone 7 EMMCBOOT on Nokia Lumia 800

This is the reverse procedure I used after experimenting with a custom Lumia 800 `EMMCBOOT.MBN`.

## 1. Find the Lumia disk

```bash
diskutil list
```

Identify the external Lumia disk with the expected partition layout. In one session mine was `/dev/disk6`, but **do not assume the number stays the same**.

If it is currently `disk6`:

```bash
diskutil mount /dev/disk6s3
diskutil info /dev/disk6s3 | grep -E "Device Node|Volume Name|Mount Point"
```

Expected mount point in my setup:

```text
/Volumes/NO NAME
```

## 2. Verify both EMMCBOOT files

Installed file:

```bash
shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

Verified stock backup:

```bash
shasum -a 256 "$HOME/Desktop/Lumia800-EMMCBOOT-stock-v10-20260828-103953.MBN"
```

My stock SHA-256:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

Do not write anything if the stock backup does not match the expected file.

## 3. Save the currently installed experimental file

```bash
cp -p "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN" \
"$HOME/Desktop/Lumia800-experimental-current-backup.MBN"
```

## 4. Restore stock

```bash
cp -f "$HOME/Desktop/Lumia800-EMMCBOOT-stock-v10-20260828-103953.MBN" \
"/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"

sync

shasum -a 256 "/Volumes/NO NAME/IMAGE2/EMMCBOOT.MBN"
```

The final hash must be:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

## 5. Safely detach

Example only:

```bash
diskutil unmount /dev/disk6s3
diskutil eject /dev/disk6
```

Then:

1. disconnect USB;
2. wait about 15 seconds;
3. press Power until the vibration and release;
4. allow time for the Nokia logo / WP7 boot.

If necessary, use a normal power-cycle. Avoid factory-reset key combinations unless you intentionally want a reset.

Replacing this saved `IMAGE2/EMMCBOOT.MBN` by itself is not a filesystem format operation and does not itself erase the WP7 user-data partitions.
