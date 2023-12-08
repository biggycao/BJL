#!/bin/bash
lsblk -f
read -r -p "which disk do you want to install BJL on? (example /dev/sda) " disk
echo "Partition Manually. God knows what you're doin' w/ the partitions."
# some users wanna seperate /home and /usr partition. And I'm too lazy to sort all of these things out.
fdisk $disk 

sh arch