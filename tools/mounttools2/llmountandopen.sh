#!/bin/bash

sudo /usr/bin/llmounthelper.sh $@
if mountpoint -q  /media/disk/${2} ; then
	thunar /media/disk/${2} &
elif [ "${1}" = "mount" ] ; then 
	zenity --error --text "Mounting ${2} failed"
fi
