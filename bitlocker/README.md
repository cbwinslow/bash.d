# BitLocker Mounting Scripts

## Overview
These scripts allow you to mount and unmount a BitLocker-encrypted drive on Linux using dislocker. The primary script uses the dislocker tool to decrypt Microsoft BitLocker-encrypted partitions and make their contents accessible in a Linux environment.

## System Requirements
- Linux distribution with sudo privileges
- `dislocker` package installed (`sudo apt install dislocker` or equivalent for your distro)
- Root privileges for mounting file systems
- FUSE (Filesystem in Userspace) support
- NTFS support (`ntfs-3g` package recommended)

## Files
- `mount_bitlocker_drive.sh` - Mounts the BitLocker drive using dislocker decryption
- `unmount_bitlocker_drive.sh` - Safely unmounts the BitLocker drive
- `README.md` - This comprehensive documentation file

## Technical Background
BitLocker is Microsoft's full-disk encryption technology that encrypts entire volumes. On Linux, we can access BitLocker-encrypted volumes using dislocker, which acts as a decryption layer between the encrypted disk and the file system. Dislocker creates a virtual unencrypted disk image that can be mounted normally by the Linux kernel.

### How BitLocker Encryption Works
BitLocker uses AES encryption with a 128-bit or 256-bit key to encrypt data on the disk. The encryption key is protected by a password, a Trusted Platform Module (TPM), or a recovery key. For this implementation, we're using a password-based unlock method.

### How dislocker Works
1. dislocker reads the encrypted BitLocker partition
2. It decrypts the metadata to retrieve the volume master key (VMK)
3. Using the VMK, it decrypts the file system data
4. It presents a decrypted virtual disk image at the specified mount point
5. The Linux kernel can then mount this image using normal file system tools

## Mount Script Architecture
The `mount_bitlocker_drive.sh` script performs the following sequence:

1. **Preparation Phase**:
   - Checks for existing mount points to prevent conflicts
   - Creates necessary directory structures (`/mnt/bitlocker` and `/mnt/bitlockermount`)

2. **Decryption Phase**:
   - Executes dislocker with the `-u` parameter to specify the password
   - Creates a decrypted image in the dislocker mount point
   - The command used: `dislocker -V /dev/sda1 -u123qweasd -- "$DISLOCKER_MOUNT"`

3. **Mounting Phase**:
   - Uses the `mount` command with the `loop` option to mount the decrypted image
   - The dislocker output file is located at `$DISLOCKER_MOUNT/dislocker-file`
   - Mounts to the user-accessible path at `/mnt/bitlockermount`

## Device Path Configuration
The scripts are configured for your 4TB drive at `/dev/sda1`, which matches the following hardware configuration:
- Drive model: ST4000NM0035-1V4 (4TB Seagate drive)
- Partition structure: GPT with a single Microsoft Basic Data partition at `/dev/sda1`
- File system: NTFS (encrypted with BitLocker)

If your device path differs, you can modify the DEVICE variable in the mount script to match your drive's path (e.g., `/dev/sdb1`, `/dev/sdc1`, etc.).

## Usage Instructions

### To mount the drive:
1. Navigate to the bitlocker directory:
   ```bash
   cd /home/cbwinslow/bash.d/bitlocker/
   ```

2. Run the mount script:
   ```bash
   ./mount_bitlocker_drive.sh
   ```
   Note: The script requires execution permissions. If you get a "Permission denied" error, run: `chmod +x mount_bitlocker_drive.sh`

3. When prompted, enter the BitLocker password: `123qweasd`
   Note: The password will not be displayed as you type for security reasons.

4. The drive will be mounted at `/mnt/bitlockermount` and accessible for reading and writing.

### To unmount the drive:
1. Navigate to the bitlocker directory:
   ```bash
   cd /home/cbwinslow/bash.d/bitlocker/
   ```

2. Run the unmount script:
   ```bash
   ./unmount_bitlocker_drive.sh
   ```

3. The drive will be safely unmounted, detaching it from the file system.

## File System Permissions and Access
The drive is mounted with read/write permissions, allowing both reading and modification of files. The mounted file system will have permissions that reflect the original NTFS permissions but adapted to Linux file system conventions.

Files and directories created or modified while mounted will maintain their NTFS attributes but may have Linux ownership applied. The `umask=000` parameter ensures full permissions are maintained when accessing the files.

## Security Considerations
- The password `123qweasd` is embedded in the mounting process and may be visible in system logs or process lists
- Run these scripts only on trusted systems where other users cannot access your process information
- Unmount the drive when not in use to minimize exposure of sensitive data
- Ensure your Linux system is up-to-date to prevent potential security vulnerabilities

## Troubleshooting Comprehensive Guide

### General Mount Issues

**Problem**: "No BitLocker partitions found"
**Solution**: Verify the drive is properly connected and detected by running `lsblk` or `fdisk -l`. If the drive is detected but not found by the script, check that the device path in the script matches your actual device.

**Problem**: "Dislocker isn't installed" or "Command not found"
**Solution**: Install dislocker using your package manager: `sudo apt install dislocker` (Debian/Ubuntu) or equivalent for your distribution.

**Problem**: "Permission denied" errors
**Solution**: Ensure you have sudo privileges. If running through an AI agent, ensure the agent has sudo access configured properly. You can test with: `sudo -v` to verify.

**Problem**: "Operation not permitted" when mounting
**Solution**: This typically means another process is using the mount point. Check with: `lsof | grep bitlockermount`. Kill any processes if necessary or unmount with: `sudo umount /mnt/bitlockermount`.

### Dislocker-Specific Issues

**Problem**: "None of the provided decryption mean is decrypting the keys. Abort."
**Solution**: This error indicates the password is incorrect. Verify that `123qweasd` is the correct BitLocker password. If you're using a recovery key instead of a password, you'll need to modify the command to use the `-r` flag instead of `-u`.

**Problem**: "Unable to grab VMK or FVEK. Abort."
**Solution**: Similar to above, this indicates authentication failure. Check the password. If using a recovery key, ensure it's properly formatted (e.g., XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX).

**Problem**: "No such file or directory" when accessing /mnt/bitlockermount
**Solution**: The dislocker-file wasn't created, suggesting the decryption step failed. Check the output of the dislocker command for specific errors.

### Drive-Specific Issues

**Problem**: Device path /dev/sda1 doesn't exist
**Solution**: The system may have reassigned drive letters. Check available drives with `lsblk` or `fdisk -l`. When the drive is plugged in, note which device path appears/disappears.

**Problem**: "Invalid argument" during mounting
**Solution**: This could be due to filesystem corruption on the BitLocker drive. Try using `ntfsfix` if the drive is NTFS-based: `sudo ntfsfix /dev/sda1` (when unmounted).

**Problem**: Drive appears mounted but files show as corrupted
**Solution**: The decryption was successful but the filesystem may be partially corrupted. Run filesystem checks using Windows recovery tools on a Windows system.

### Process and Mount Point Issues

**Problem**: Drive already mounted error
**Solution**: Verify the mount status with `mount | grep bitlocker`. If the drive is truly mounted, you can access it normally. If it appears mounted but isn't functional, forcefully unmount: `sudo umount -f /mnt/bitlockermount` and `sudo umount -f /mnt/bitlocker`.

**Problem**: Cannot create directories /mnt/bitlocker or /mnt/bitlockermount
**Solution**: Permissions issue. Ensure you have sudo access. If the directories exist but are owned by root, remove them: `sudo rm -rf /mnt/bitlocker /mnt/bitlockermount`.

### Debugging Commands

1. **Check if drive is physically detected**:
   ```bash
   lsblk
   ```

2. **Check current mount points**:
   ```bash
   mount | grep bitlocker
   ```

3. **View detailed dislocker information**:
   ```bash
   sudo dislocker -V /dev/sda1 -u123qweasd -- /mnt/bitlocker
   ```

4. **Check for NTFS partition**:
   ```bash
   sudo blkid /dev/sda1
   ```

5. **Check for BitLocker signature**:
   ```bash
   sudo hexdump -C /dev/sda1 | head -20
   # Look for BitLocker signature patterns
   ```

6. **Check process list for dislocker activity**:
   ```bash
   ps aux | grep dislocker
   ```

7. **Check for open files on mount points**:
   ```bash
   lsof +D /mnt/bitlockermount
   ```

## Verification Steps

### After Mounting
1. Check mount status: `mount | grep bitlockermount`
2. List files: `ls -la /mnt/bitlockermount`
3. Check disk space: `df -h /mnt/bitlockermount`

### After Unmounting
1. Verify unmount: `mount | grep bitlockermount` (should return no results)
2. Check directories are empty: `ls -la /mnt/bitlockermount` (should show empty mount point)

## Manual Operation (Bypassing Scripts)

### To manually mount without scripts:
```bash
# Preparation
sudo mkdir -p /mnt/bitlocker /mnt/bitlockermount

# Decrypt with dislocker using password-based authentication
sudo dislocker -V /dev/sda1 -u123qweasd -- /mnt/bitlocker

# Mount the decrypted image
sudo mount -o loop,umask=000 /mnt/bitlocker/dislocker-file /mnt/bitlockermount

# Verify access
ls -la /mnt/bitlockermount
```

### To manually unmount without scripts:
```bash
# Unmount the file system
sudo umount /mnt/bitlockermount

# Unmount the dislocker virtual disk
sudo umount /mnt/bitlocker

# Optional: Remove mount directories
sudo rmdir /mnt/bitlockermount /mnt/bitlocker
```

## Alternative Authentication Methods
If your BitLocker drive uses a different authentication method, adjust accordingly:

### Recovery Key (48-digit key):
Replace the authentication in the dislocker command:
```bash
sudo dislocker -V /dev/sda1 -rRECOVERY_KEY_HERE -- /mnt/bitlocker
```

### TPM/Startup Key:
These require special handling that may not work in the same way on Linux. You may need to decrypt on a Windows system first.

### Smart Card:
Not supported by dislocker on Linux.

## Drive Information
- Physical device: `/dev/sda1` - Seagate 4TB drive (ST4000NM0035-1V4)
- Partition: Microsoft Basic Data (typical for BitLocker)
- File system: NTFS (encrypted with BitLocker)
- Size: 3.64 TiB (4000787030016 bytes)
- Sector size: 512 bytes
- Encryption: BitLocker with password protection

## For AI Agents
When running these scripts:
1. Ensure the working directory is set to `/home/cbwinslow/bash.d/bitlocker/`
2. Execute scripts with `./script_name.sh` rather than just `script_name.sh`
3. Be prepared to enter the password `123qweasd` when prompted
4. Check return codes of operations to verify success before proceeding
5. Always unmount before shutting down to ensure data integrity
6. Before running mount script, verify the drive is present in `lsblk` output
7. If using in a non-interactive context, consider using echo for password input: `echo "123qweasd" | ./mount_bitlocker_drive.sh`

## Known Limitations
- The script assumes a specific device path (`/dev/sda1`), which may change between system boots
- Password-based authentication only (no support for recovery keys in this script)
- No automatic detection of available mount points if defaults are in use
- No built-in file integrity checking after mounting

## Update Notes for Future Modifications
- If device path changes, update the DEVICE variable in the mount script
- If password changes, update the RECOVERY_KEY variable in the mount script
- For different drive sizes, the mounting process should work without modifications
- To change mount points, update the DISLOCKER_MOUNT and NTFS_MOUNT variables in both scripts