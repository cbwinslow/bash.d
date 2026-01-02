#!/usr/bin/env bash
  set -euo pipefail

  dev="${1:-}"

  if [[ -z "$dev" ]]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
  fi

  if [[ ! -b "$dev" ]]; then
    echo "Not a block device: $dev"
    exit 1
  fi

  echo "About to ERASE ALL DATA on $dev"
  lsblk -dno NAME,SIZE,MODEL "$dev"
  read -r -p "Type ERASE to continue: " confirm
  [[ "$confirm" == "ERASE" ]] || exit 1

  # Unmount any mounted partitions on the device
  lsblk -ln -o MOUNTPOINT "$dev" | awk 'NF{print}' | while read -r mp; do
    umount "$mp"
  done

  # Remove filesystem signatures
  wipefs -a "$dev"

  # Prefer discard on SSDs; fall back to zeroing
  if blkdiscard -f "$dev"; then
    echo "blkdiscard done"
  else
    echo "blkdiscard failed; falling back to dd"
    dd if=/dev/zero of="$dev" bs=16M status=progress oflag=direct
    sync
  fi

  echo "Wipe complete."
