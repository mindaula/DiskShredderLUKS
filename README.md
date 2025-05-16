# DiskShredderLUKS
Securely wipes block devices by repeatedly encrypting, overwriting, and optionally formatting.


# secure_erease

A secure Bash script to irreversibly wipe block devices (e.g. USB, HDD, SSD) using LUKS2 encryption and multiple overwrite passes. Optional formatting is supported.

## Why Secure Erase?

Simple formatting or file deletion does not truly remove data – it can be recovered. This script:
- Uses randomly generated passwords for LUKS2 encryption
- Overwrites encrypted data with zeros and random data
- Repeats the process multiple times
- Can format the device at the end

This guarantees complete data destruction.

## Requirements

- Must be run as root (`sudo`)
- Device must be **unmounted**
- Tools: `cryptsetup`, `dd`, `mkfs`, `wipefs`, `tr`, `head`, `bash`

## Full Option Table

| Option / Parameter    | Required | Description                                                                                                  | Example                                     |
|-----------------------|----------|--------------------------------------------------------------------------------------------------------------|---------------------------------------------|
| `/dev/sdX`            | Yes      | Target block device to wipe. Must be unmounted.                                                              | `/dev/sdb`                                   |
| `-p <1-5>`            | No       | Number of secure passes (each pass = zero + random overwrite). Default is 1.                                 | `-p 3`                                       |
| `-fs <filesystem>`    | No       | Format the device at the end using `mkfs.<type>` (e.g. ext4, xfs, vfat, exfat, etc.).                        | `-fs ext4`                                   |
| `sudo`                | Yes      | Script must be run with root privileges.                                                                     | `sudo ./secure_erease.sh /dev/sdb`       |
| `umount /dev/sdX1`    | Yes      | Unmount all mounted partitions on the device before running.                                                 | `umount /dev/sdb1`                           |

## Example Usages

| Command Example                                  | Description                                             |
|--------------------------------------------------|---------------------------------------------------------|
| `sudo ./secure_erease.sh /dev/sdb`           | Wipe device with 1 pass (default), no formatting        |
| `sudo ./secure_erease.sh /dev/sdc -p 3`      | Wipe device with 3 overwrite passes                     |
| `sudo ./secure_erease.sh /dev/sdc -p 2 -fs xfs` | Wipe device with 2 passes and format with XFS         |

## How to Identify the Correct Device

Use `lsblk` or `fdisk -l` to find your target:

```bash
lsblk
Example output:

NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  500G  0 disk
├─sda1   8:1    0  100G  0 part /
sdb      8:16   1   16G  0 disk    # likely USB drive
Only use devices you are 100% sure can be wiped.


Script Workflow
Verify root privileges

Verify device and unmounted state

Wipe partition table signatures using wipefs -a

For each pass:

Create LUKS2 container with random password

Open as /dev/mapper/cryptdevice

Overwrite with zeros and random data

Close LUKS container

Optionally:

Reopen with new password

Format with mkfs.<type>

Close container



Sample Output

Wiping partition signatures on /dev/sdb...
Starting secure erase of /dev/sdb with 3 passes...
Generating random 200-character password for pass 1...
Creating LUKS2 container...
Overwriting with zeros...
Overwriting with random data...
Pass 2...
Pass 3...
Formatting decrypted device with filesystem ext4...
Secure erase of /dev/sdb completed.
Warning



This script will permanently destroy all data on the specified device.
Always double-check device names with lsblk or fdisk -l.

