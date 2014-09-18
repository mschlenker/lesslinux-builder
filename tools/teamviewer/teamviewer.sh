#!/bin/bash
# encoding: utf-8

# Wrapper script for TeamViewer
# The non free component TeamViewer 9 must be present in /lesslinux/blob

PATH=:/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
TVHOME=/opt/teamviewer/teamviewer9

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh

tvnotfound="Could not find TeamViewer - make sure the binary tarball is available in /lesslinux/blob."
[ $lang = de ] && tvnotfound="Konnte TeamViewer nicht finden - Stellen Sie bitte sicher, dass das Tar-Archiv in /lesslinux/blob liegt."

if [ '!' -f "${TVHOME}/teamviewer" ] ; then
	zenity --error --text "$tvnotfound" 
	exit 1
fi

# Start the teamviewer daemon
# ( "${TVHOME}/tmp/teamviewer8/tv_bin/teamviewerd" -n -f --profile-dir /tmp/teamviewer8 )
# Start TeamViewer

cd "$TVHOME"
./teamviewer 
