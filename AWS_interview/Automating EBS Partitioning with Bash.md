# Automating EBS Partitioning with Bash

## Overview
This guide demonstrates how to create two partitions on a 100GB AWS EBS volume using a non-interactive Bash script. The process involves automating partition creation, formatting, and mounting.

---

## Bash Script for Non-Interactive Partitioning

```bash
#!/bin/bash

# Set the disk name (replace xvdf with your volume's device name)
DISK="/dev/xvdf"

# Create the partition table (GPT)
sudo parted -s $DISK mklabel gpt

# Create the first partition (50GB)
sudo parted -s $DISK mkpart primary ext4 0% 50%

# Create the second partition (remaining space)
sudo parted -s $DISK mkpart primary ext4 50% 100%

# Format the partitions with ext4
sudo mkfs.ext4 ${DISK}1
sudo mkfs.ext4 ${DISK}2

# Create mount points
sudo mkdir -p /mnt/partition1
sudo mkdir -p /mnt/partition2

# Mount the partitions
sudo mount ${DISK}1 /mnt/partition1
sudo mount ${DISK}2 /mnt/partition2

# Display partition and mount status
lsblk
df -h
```

---

## Explanation

1. **Set the Disk Device**
   - Specify the EBS volume's device name, e.g., `/dev/xvdf`.

2. **Create a GPT Partition Table**
   - Use `parted -s` to create a new GPT partition table.

3. **Create Partitions**
   - First partition: 0% to 50% (50GB).
   - Second partition: 50% to 100% (remaining 50GB).

4. **Format Partitions**
   - Use `mkfs.ext4` to format both partitions with the ext4 filesystem.

5. **Mount Partitions**
   - Mount the partitions to specific directories.

6. **Verify Results**
   - Display partition and mount status using `lsblk` and `df -h`.

---

## Run the Script

1. Save the script to a file, e.g., `partition_volume.sh`:
   ```bash
   nano partition_volume.sh
   ```

2. Make it executable:
   ```bash
   chmod +x partition_volume.sh
   ```

3. Run the script:
   ```bash
   sudo ./partition_volume.sh
   ```

---

## Persist Mount Points (Optional)

To ensure the partitions are mounted automatically after a reboot:

1. Get the UUIDs:
   ```bash
   sudo blkid
   ```

2. Add entries to `/etc/fstab`:
   ```bash
   sudo nano /etc/fstab
   ```
   Example:
   ```
   UUID=<UUID1> /mnt/partition1 ext4 defaults 0 0
   UUID=<UUID2> /mnt/partition2 ext4 defaults 0 0
   ```

3. Test:
   ```bash
   sudo mount -a
   ```

---

## Conclusion
This script automates the entire process of partitioning and setting up an AWS EBS volume, saving time and reducing the risk of manual errors. Customize it as needed for your environment!
