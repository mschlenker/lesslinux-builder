#!/bin/bash

[ "$#" -lt  1 ] && echo "Please provide devicename to mount" && exit 1

if mount | grep "$1 " ; then
	mountpoint="` mount | grep "^$1 " | awk '{ print $3 }' `"
	exec thunar "$mountpoint"
else
	llaskpass-mount.rb | sudo -S mount "$1"
	if mount | grep "$1 " ; then
		mountpoint="` mount | grep "^$1 " | awk '{ print $3 }' `"
		exec thunar "$mountpoint"
	else
		exec llerrormessage.rb mountfailed
	fi
fi

