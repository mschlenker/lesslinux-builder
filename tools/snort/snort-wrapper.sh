#!/bin/bash
# encoding: utf-8

if [ -x /lesslinux/blobpart/snort/snort-wrapper.sh ] && [ "` pwd `" '!='  /lesslinux/blobpart/snort ] ; then
	cd /lesslinux/blobpart/snort
	exec bash snort-wrapper.sh 
fi
if mountpoint /lesslinux/blobpart ; then
	echo "BLOB partition is mounted, continue"
else
	zenity --error --text "Bitte installieren Sie das System zunächst auf einen USB-Stick, um genügend Speicherplatz für Regeln und Logdateien zu haben."
	exit 1 
fi

pwd=` dirname $0 ` 
cd "$pwd"

ruby -I . -I /usr/share/lesslinux/drivetools snort-wrapper.rb 
