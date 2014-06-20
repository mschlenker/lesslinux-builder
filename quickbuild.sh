#!/bin/bash

# Script to do a quick and dirty default build of LessLinux (unstable)
# Standard paths are used. Stage02 is built with three threads. An ext4
# or btrfs mounted disk at /mnt/archiv or /mnt/archiv/LessLinux is 
# expected. 
#
# If the partition is not present, you are prompted to mount.
# 
# If no swap is present, you are prompted to add some swap. 

if [ ` id -u ` -gt 0 ] ; then
	echo "Please run this script as root!"
	exit 1
fi

mounted=""
mountpoint -q /mnt/archiv && mounted="/mnt/archiv"
mountpoint -q /mnt/archiv/LessLinux && mounted="/mnt/archiv/LessLinux"

if [ -z "$mounted" ] ; then 
	echo "Please mount an ext4 or btrfs formatted partition with sufficient space"
	echo "(40GB recommended) at /mnt/archiv or /mnt/archiv/LessLinux."
	echo ""
	echo "Then press Enter to continue - or press Ctrl+C to cancel"
	read mnt
	mounted=""
	mountpoint -q /mnt/archiv && mounted="/mnt/archiv"
	mountpoint -q /mnt/archiv/LessLinux && mounted="/mnt/archiv/LessLinux"
	if [ -z "$mounted" ] ; then
		echo "Sorry, no mountpoint found."
		exit 1
	fi
fi

if [ ` cat /proc/swaps | wc -l ` -lt 2 ] ; then
	echo "We recommend adding some swap."
	echo ""
        echo "Press enter to continue - or press Ctrl+C to cancel"
	read swap
fi

mkdir -p /mnt/archiv/LessLinux/llbuild
mkdir -p /mnt/archiv/LessLinux/src

if [ -f /mnt/archiv/LessLinux/llbuild/stage01.tar.xz ] ; then
	echo "Stage01 seems to be ready."
	echo ""
        echo "Press enter to continue - or press Ctrl+C to cancel"
        read sone
else
	echo "Building stage01 -please be patient."
	touch /mnt/archiv/LessLinux/llbuild/stage01.log
	Terminal --hide-menubar -T "LOG: stage01" -e "tail -f /mnt/archiv/LessLinux/llbuild/stage01.log" &
	ruby -I. builder.rb -s 2,3 -n -l -t 3 -u --no-stracalyze --ignore-arch  >> /mnt/archiv/LessLinux/llbuild/stage01.log 2>&1 
fi






