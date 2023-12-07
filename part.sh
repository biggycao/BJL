#!/bin/bash
lsblk -f
read -r -p "which disk do you want to install BJL on? (example /dev/sda) " disk
parted --script $disk mklabel gpt