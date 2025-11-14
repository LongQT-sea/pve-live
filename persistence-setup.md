## Create a bootable Proxmox VE live USB drive with a persistence filesystem

These instructions focus on creating the ext4 persistence partition on a USB drive, but you can create it on an internal hard drive as well.
  - [Windows](#windows)
  - [Linux](#linux)
  - [macOS](#macos)

> [!Note]
> You can modify GRUB config file at `PVE-LIVE/boot/grub/grub.cfg` after creating the live boot USB drive.

### Windows
- **Lazy method (slow):** Use [Rufus](https://github.com/pbatard/rufus/releases). After selecting the ISO file, adjust the **persistent partition size** slider.

- **Manual method (faster):** Open **Windows Terminal** or **PowerShell** as Administrator.
    > Replace `X` with your USB disk number:
    ```
    diskpart
    list disk
    sel disk X
    clean
    con mbr
    cre par pri size=2000
    format fs=fat32 quick label=pve-live
    active
    assign letter=V
    cre par pri
    exit
    ```
> [!Note]
> After running these commands, it will create **2 partitions**:
> - Partition 1: Mounted as `V:\`. Copy all files and folders from the live ISO to this partition.
> - Partition 2: Will be formatted in Linux for persistence storage (see **Step 4: Format `/dev/sdX2`** in [Linux](#linux) section).

---

### Linux

> [!Note]
> Replace `/dev/sdX` with your actual USB drive identifier.

1. Create partitions with fdisk:
   ```
   ls -l /dev/disk/by-id/
   
   fdisk /dev/sdX
   
   o          # new MBR table
   n          # new partition
   p          # primary
   <enter>    # partition 1
   <enter>    # default start
   +2000M     # 2GB size
   t          # change type
   c          # W95 FAT32 (LBA)
   a          # make bootable
   n          # new partition
   p          # primary
   <enter>    # partition 2
   <enter>    # default start
   <enter>    # use rest of disk
   w          # write changes
   ```

2. Format `/dev/sdX1` as FAT32 and label it `PVE-LIVE`:
   ```
   mkfs.vfat -F 32 -n "PVE-LIVE" /dev/sdX1
   ```

3. Mount `/dev/sdX1` and copy ISO content to it:
   ```
   mkdir /tmp/partition1 && mkdir /tmp/iso_mount
   mount /dev/sdX1 /tmp/partition1
   mount /path/to/pve-live-iso /tmp/iso_mount
   cp -r /tmp/iso_mount/* /tmp/partition1/ && sync
   ```

4. Format `/dev/sdX2` with ext4 and label it `persistence`:
   ```
   mkfs.ext4 -L persistence /dev/sdX2
   ```

5. Mount `/dev/sdX2` and create `persistence.conf`:
   ```
   mkdir /tmp/partition2
   mount /dev/sdX2 /tmp/partition2
   echo "/ union" > /tmp/partition2/persistence.conf
   umount /tmp/partition1 /tmp/iso_mount /tmp/partition2
   ```

---

### macOS

> [!Note]
> Replace `diskX` with your actual USB drive identifier.

1. Create partitions with `diskutil`:
   ```
   diskutil list
   diskutil partitionDisk diskX 2 MBR FAT32 "PVE-LIVE" 2g ExFAT "persistence" 0
   diskutil unmountDisk /dev/diskX
   sudo fdisk -e /dev/diskX <<< $'flag 1\nwrite\nexit\n'
   diskutil mount diskXs1
   ```

2. Copy ISO contents to the USB:
   - Download and extract 7-zip: https://www.7-zip.org/a/7z2501-mac.tar.xz
   ```
   cd ~/Downloads/7z2501-mac
   ./7zz x ~/Downloads/pve-9_live_lxde.iso -o/Volumes/PVE-LIVE && sync
   diskutil unmountDisk /dev/diskX
   ```

3. Boot from the USB and create the persistence partition:
   - See **Step 4: Format `/dev/sdX2`** in the [Linux](#linux) section.
