# Research artifacts

This directory contains files used in the **Nokia Lumia 800 / Sea Ray** bootloader and Android bring-up research documented in this repository.

> [!CAUTION]
> Do not treat these files as universal Lumia 800 firmware. Always verify hashes, keep your own stock backup, and never replace `EMMCBOOT.MBN` unless you understand the recovery path.

## Included artifact

### Experimental Fastboot EMMCBOOT

Path:

```text
artifacts/experimental/Lumia800-experimental-EMMCBOOT-20260828-100931.MBN
```

Size:

```text
21,824 bytes
```

SHA-256:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

Purpose:

- experimental Lumia 800 / Sea Ray USB bring-up;
- intended to reach a minimal Fastboot environment;
- contains strings such as `LUMIA800_FASTBOOT`, `getvar:`, `download:`, `reboot` and `fastboot`;
- intended for testing before Android boot-image work.

This file is **not** the stock Windows Phone 7 bootloader.

---

# Stock Windows Phone 7 EMMCBOOT

The stock WP7 file is intentionally **not published in this repository**.

The verified stock backup used during this research has SHA-256:

```text
bf467e7bef7fcdca10dda2cc0e9ea955f1142d7804327ce3b042b233848443cf
```

The correct workflow is to create and keep your **own backup** from:

```text
IMAGE2/EMMCBOOT.MBN
```

before installing any experimental loader.

See:

- [`../FASTBOOT.md`](../FASTBOOT.md)
- [`../RESTORE_WP7.md`](../RESTORE_WP7.md)

for the documented switching and recovery procedure.

> [!IMPORTANT]
> Never confuse the two hashes:
>
> ```text
> bf467e7b...  = stock WP7 EMMCBOOT used in this research
> 7777c744...  = experimental Fastboot EMMCBOOT
> ```

---

# Larger research archives

The following source/build archives were audited during this project but are not kept directly in `main` because of their size or because they are better suited to a release/archive distribution.

| Artifact | Approx. size | SHA-256 | Notes |
|---|---:|---|---|
| `lumia800-fat(2).zip` | ~20 MB | `04694c44046ed9b4be70eefb7f5e5b350ea211824f18b9183f80c4056f09a65a` | FAT16 backup containing `IMAGE2` |
| `arm-2009q1-toolchain(3).zip` | ~71 MB | `5ec49996567803a790043f8a408c2dc2183a3d53154cb04f7d86bb7154484da0` | Sourcery GCC 4.3.3 toolchain package |
| `lumia800-device-tree-audit(3).zip` | ~3.9 MB | `d72cdf8977eadbc860719453e7dbef3872ef1143783c7c42f41f0cebafac80d1` | Current CM13 Lumia 800 device-tree snapshot |
| `lumia800-kernel-v0.5-source(4).zip` | ~384 MB | `2ce8034cfc884d7bbe4c5371559fecc347867427a1f7ac26a394f7cfbcb6be9e` | Linux 3.0.1+ kernel source/build snapshot |

Their hashes are also recorded in [`../SHA256SUMS.txt`](../SHA256SUMS.txt).

---

# Historical ENTRY PROBE file

An earlier test referenced another EMMCBOOT build with SHA-256:

```text
135d642385ff44fa93ce5b3368c25f6ae55eb9bab2987f76271f172e4da363aa
```

That file is **not the same** as the experimental Fastboot binary currently included here.

Do not treat:

```text
135d6423...
```

and:

```text
7777c744...
```

as interchangeable builds.

---

# Recommended verification

After downloading an artifact on macOS:

```bash
shasum -a 256 <filename>
```

For the included experimental loader, the result must be:

```text
7777c74403541f7881bc6f9ace6327769a9da9c494f6bf5b8567ddef0e03f29d
```

If the hash differs, do not write the file to the phone.

---

# Current safe workflow

```text
own stock WP7 backup
        ↓
verify SHA-256
        ↓
install experimental EMMCBOOT
        ↓
verify SHA-256 on Lumia
        ↓
fastboot devices
        ↓
Fastboot diagnostics
        ↓
restore own stock EMMCBOOT if needed
        ↓
Windows Phone 7
```

The project deliberately avoids presenting `fastboot flash boot` as the normal development path. The preferred future milestone is a verified temporary `fastboot boot boot.img` flow from RAM.
