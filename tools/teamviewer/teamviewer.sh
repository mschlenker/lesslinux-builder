#!/bin/bash
# encoding: utf-8

# Wrapper script for TeamViewer
# The non free component TeamViewer 10 must be present in /lesslinux/blob

# Warning: This script currently only works with environments where TeamViewer is pre-installed and a display manager is running!

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

rest="If no TeamViewer ID is shown, the user interface has to be restarted. Restart now?"
[ $lang = de ] && rest="Falls keine TeamViewer ID angezeigt wird, muss die grafische Öberfläche neu gestartet werden. Jetzt neu starten?"

tvnotfound="Could not find TeamViewer - make sure you have an internet connection to start the installation now."
[ $lang = de ] && tvnotfound="Konnte TeamViewer nicht finden - Stellen Sie bitte sicher, dass Sie über eine Internetverbindung verfügen, um die Installation jetzt zu starten."

if [ '!' -f "${TVHOME}/teamviewer" ] ; then
	zenity --error --text "$tvnotfound" 
	sudo /usr/bin/blobinstall.sh --check teamviewer 
fi

# Start Teamviewer:

su surfer -c /opt/teamviewer/teamviewer/tv_bin/TeamViewer &
sleep 10
if zenity --question --text "$rest" ; then
	killall -15 teamviewerd
	sleep 3
	/opt/teamviewer/teamviewer/tv_bin/teamviewerd -d
	touch /home/surfer/.start_teamviewer
	chown surfer:surfer /home/surfer/.start_teamviewer
	# killall -15 lxdm-binary
	/usr/bin/restart_xdm
fi

exit 0 



####### 

if [ -x /opt/teamviewer/teamviewer/tv_bin/TeamViewer ] ; then
	exec /opt/teamviewer/teamviewer/tv_bin/TeamViewer
else
	zenity --warning --text 'TeamViewer not found, please install first!'
	exit 1
fi

# FIXME!



tvnotfound="Could not find TeamViewer - make sure you have an internet connection to start the installation now."
[ $lang = de ] && tvnotfound="Konnte TeamViewer nicht finden - Stellen Sie bitte sicher, dass Sie über eine Internetverbindung verfügen, um die Installation jetzt zu starten."

if [ '!' -f "${TVHOME}/teamviewer" ] ; then
	zenity --error --text "$tvnotfound" 
	sudo /usr/bin/blobinstall.sh --check teamviewer 
fi




# Start the teamviewer daemon
# ( "${TVHOME}/tmp/teamviewer8/tv_bin/teamviewerd" -n -f --profile-dir /tmp/teamviewer8 )
# Start TeamViewer

unset SUDO_ASKPASS
unset SUDO_COMMAND
unset SUDO_EDITOR
unset SUDO_GID
unset SUDO_PROMPT
unset SUDO_PS1
unset SUDO_UID
unset SUDO_USER

cd "$TVHOME"
./teamviewer 
