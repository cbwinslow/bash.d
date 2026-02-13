#!/bin/bash
# Unmount script for BitLocker drive mounted with dislocker
# This unmounts the drive mounted by mount_bitlocker_drive.sh

NTFS_MOUNT="/mnt/bitlockermount"
DISLOCKER_MOUNT="/mnt/bitlocker"

# Unmount the NTFS mount point first
sudo umount "$NTFS_MOUNT" 2>/dev/null

# Then unmount the dislocker mount point
sudo umount "$DISLOCKER_MOUNT" 2>/dev/null

echo "BitLocker drive unmounted from $NTFS_MOUNT"