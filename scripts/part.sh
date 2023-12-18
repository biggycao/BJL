#!/bin/bash
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
MAKEFLAGS=-j$(nproc)
lsblk -f
read -r -p "which disk do you want to install BJL on? (example /dev/sda) " disk
fdisk $disk
read -r -p "boot partition? (example /dev/sda1) " boot
read -r -p "swap? (example /dev/sda2) " swap
read -r -p "root partition? (example /dev/sda3) " root

# Format partitions
mkfs.fat -F32 $boot
mkswap $swap
mkfs.ext4 $root

# Display partition information
parted $disk print
mount $root /mnt/lfs
swapon $swap
mkdir $HOME/BJLtempins
cp ./* $HOME/BJLtempins
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
wget https://mirrors.ustc.edu.cn/lfs/lfs-packages/lfs-packages-12.0.tar --continue --directory-prefix=$LFS/sources
cd $LFS/sources
tar -xf lfs-packages-12.0.tar
cp 12.0/* .
sh $LFS/BJLtempins/arch
