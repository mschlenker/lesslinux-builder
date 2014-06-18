#!/bin/bash
# encoding: utf-8

if grep -q 'mattias:' /etc/passwd ; then
	echo '===> Found unprivileged user mattias, skipping...'
else
	echo '===> Adding unprivileged user mattias'
	adduser -h /home/mattias -s /bin/bash -D -u 1011 mattias
fi

swaps=` cat /proc/swaps | wc -l `
if [ "$swaps" -lt 2 ] ; then
	swp=` blkid -L LessLinux_swap ` 
	if swapon "$swp" ; then
		echo '===> Activated swap'
	else 
		echo '+++> Please add some swap - you might run into memory trouble otherwise'
	fi 
fi 

if mountpoint -q /mnt/archiv ; then
	echo '===> Found mountpoint /mnt/archiv, skipping...'
else
	echo '===> Mounting /mnt/archiv'
	mkdir -p /mnt/archiv
	dev=` blkid -L LessLinux_build` 
	if [ -z "$dev" ] ; then
		echo '+++> Please format a filesystem labeled LessLinux_build (ext4 or btrfs)'
		echo '+++> or manually mount your build partition at /mnt/archiv - exiting'
		exit 1
	fi
	mount "$dev" /mnt/archiv
	if mountpoint -q /mnt/archiv ; then
		echo '===> Mounting /mnt/archiv successful'
	else
		echo '+++> Mount failed for '"${dev} - exiting" 
		exit 1
	fi
	mkdir -p /mnt/archiv/LessLinux 
	echo '===> Done. Go to /mnt/archiv/LessLinux/llbuilder and have fun!'
fi
