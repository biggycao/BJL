#!/bin/bash
lsblk -f
read -r -p "which disk do you want to install BJL on? (example /dev/sda) " disk
#!/bin/bash

# Variables for disk and partitions
EFI_SIZE="1G"           # Size of EFI partition
SWAP_SIZE="6G"          # Size of Swap partition

# Partition the disk
sudo parted $disk mklabel gpt \
  mkpart primary fat32 1MiB $EFI_SIZE \
  set 1 esp on \
  mkpart primary linux-swap $EFI_SIZE $(($EFI_SIZE + $(echo $SWAP_SIZE | sed 's/G//') * 1024)) \
  mkpart primary ext4 $(($EFI_SIZE + $(echo $SWAP_SIZE | sed 's/G//') * 1024 + 1)) 100%

# Format partitions
sudo mkfs.fat -F32 ${disk}1
sudo mkswap ${disk}2
sudo mkfs.ext4 ${disk}3

# Display partition information
sudo parted $disk print
sh arch
