#!/bin/bash
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
MAKEFLAGS=-j$(nproc)
lsblk -f
read -r -p "which disk do you want to install BJL on? (example /dev/sda) " disk

# Variables for disk and partitions
EFI_SIZE="1G"           # Size of EFI partition
SWAP_SIZE="6G"          # Size of Swap partition

# Partition the disk
parted $disk mklabel gpt \
  mkpart primary fat32 1MiB $EFI_SIZE \
  set 1 esp on \
  mkpart primary linux-swap $EFI_SIZE $(($EFI_SIZE + $(echo $SWAP_SIZE | sed 's/G//') * 1024)) \
  mkpart primary ext4 $(($EFI_SIZE + $(echo $SWAP_SIZE | sed 's/G//') * 1024 + 1)) 100%

# Format partitions
mkfs.fat -F32 ${disk}1
mkswap ${disk}2
mkfs.ext4 ${disk}3

# Display partition information
parted $disk print
mount $disk /mnt/lfs
swapon $disk
mkdir $HOME/BJLtempins
cp ./* $HOME/BJLtempins
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
wget https://mirrors.ustc.edu.cn/lfs/lfs-packages/lfs-packages-12.0.tar --continue --directory-prefix=$LFS/sources
cd $LFS/sources
tar -xf lfs-packages-12.0.tar
cp 12.0/* .
sh $LFS/BJLtempins/scripts/arch
