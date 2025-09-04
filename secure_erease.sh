#!/bin/bash


if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

usage() {
    echo "Usage: $0 /dev/sdx [-p <1-5>] [-fs <filesystem>] [-luks]"
    echo "Example: $0 /dev/sda -p 3 -fs ext4 -luks"
    echo "Filesystem can be any supported by mkfs (e.g. ext4, xfs, exfat, vfat, ext2)."
    echo "-luks : Optional create LUKS-Encyption after ereasing."
    exit 1
}

REPEATS=1
FS_TYPE=""
USE_LUKS=0

if [ $# -lt 1 ]; then
    usage
fi

DEVICE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p)
            shift
            if [[ "$1" =~ ^[1-5]$ ]]; then
                REPEATS=$1
            else
                echo "Error: -p must be a number between 1 and 5."
                exit 1
            fi
            shift
            ;;
        -fs)
            shift
            FS_TYPE=$1
            shift
            ;;
        -luks)
            USE_LUKS=1
            shift
            ;;
        /dev/*)
            DEVICE=$1
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            usage
            ;;
    esac
done

if [ -z "$DEVICE" ]; then
    echo "Error: No device specified."
    usage
fi

if [ ! -b "$DEVICE" ]; then
    echo "Error: Device $DEVICE does not exist."
    exit 1
fi

echo "Wiping partition signatures on $DEVICE..."
wipefs -a "$DEVICE"

for ((i=1; i<=REPEATS; i++)); do
    echo "Pass $i/$REPEATS: Overwriting with zeros..."
    dd if=/dev/zero of="$DEVICE" bs=1M status=progress oflag=direct || { echo "Error writing zeros"; exit 1; }

    echo "Pass $i/$REPEATS: Overwriting with random data..."
    dd if=/dev/urandom of="$DEVICE" bs=1M status=progress oflag=direct || { echo "Error writing random data"; exit 1; }
done


if [ $USE_LUKS -eq 1 ]; then
    echo "Creating LUKS2 container on $DEVICE..."
    PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 200)
    echo -n "$PASSWORD" | cryptsetup luksFormat --type luks2 --batch-mode "$DEVICE" -

    echo "Opening LUKS container..."
    echo -n "$PASSWORD" | cryptsetup luksOpen "$DEVICE" cryptdevice --key-file=-


    if [ -n "$FS_TYPE" ]; then
        echo "Formatting decrypted device with filesystem $FS_TYPE..."
        if command -v mkfs.$FS_TYPE >/dev/null 2>&1; then
            mkfs.$FS_TYPE -F /dev/mapper/cryptdevice
        else
            echo "Error: mkfs.$FS_TYPE not found. Cannot format."
            cryptsetup luksClose cryptdevice
            exit 1
        fi
    fi

    echo "Closing LUKS container..."
    cryptsetup luksClose cryptdevice
    unset PASSWORD
fi

echo "Secure erase of $DEVICE completed."
