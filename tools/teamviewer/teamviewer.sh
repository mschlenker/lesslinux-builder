#!/bin/bash
# encoding: utf-8

# Wrapper script for TeamViewer
# The non free component TeamViewer 10 must be present in /lesslinux/blob

PATH=:/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
TVHOME=/opt/teamviewer/teamviewer

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh

tvnotfound="Could not find TeamViewer - make sure you have an internet connection to start the installation now."
[ $lang = de ] && tvnotfound="Konnte TeamViewer nicht finden - Stellen Sie bitte sicher, dass Sie über eine Internetverbindung verfügen, um die Installation jetzt zu starten."

if [ '!' -f "${TVHOME}/teamviewer" ] ; then
	zenity --error --text "$tvnotfound" 
	sudo /usr/bin/blobinstall.sh --check teamviewer 
fi

# Start the teamviewer daemon
# ( "${TVHOME}/tmp/teamviewer8/tv_bin/teamviewerd" -n -f --profile-dir /tmp/teamviewer8 )
# Start TeamViewer

cd "$TVHOME"
./teamviewer 
