#!/bin/bash
DEVICE="/dev/sda1"
DISLOCKER_MOUNT="/mnt/bitlocker"
NTFS_MOUNT="/mnt/bitlockermount"
RECOVERY_KEY="123qweasd" # Or use -p<PASSWORD> for password

# Create mount points if not exist
mkdir -p "$DISLOCKER_MOUNT"
mkdir -p "$NTFS_MOUNT"

# Unlock the drive
dislocker -V "$DEVICE" -u"$RECOVERY_KEY" -- "$DISLOCKER_MOUNT"

# Mount the unlocked volume
mount -o loop "$DISLOCKER_MOUNT/dislocker-file" "$NTFS_MOUNT"

exit 0
