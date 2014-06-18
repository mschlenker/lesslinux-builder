#!/bin/bash
# encoding: utf-8
	
. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
	
error_msg='The Flash archive could not be downloaded or verified!'
success_msg='Flash is installed now, please restart Firefox!'
no_profile='No firefox profile found, please start Firefox once before installing Flash!'

if [ "$lang" = "de" ] ; then
	error_msg='Das Flash-Plugin konnte nicht heruntergeladen oder verifiziert werden!'
	success_msg='Flash wurde erfolgreich installiert, bitte starten Sie Firefox neu!'
	no_profile='Kein Firefox-Profil gefunden: Bitte starten Sie einmal Firefox, bevor Sie Flash installieren.'
fi
	
paths=` cat ${HOME}/.mozilla/firefox/profiles.ini | grep Path | sed 's/Path=//g' `	
if [ -z "$paths" ] ; then
	zenity --error --text "$no_profile"
	exit 1
fi

if check_lax_sudo ; then
	sudo /usr/bin/flashinstall-downloader.sh
else
	/usr/bin/llaskpass-mount.rb | sudo -S /usr/bin/flashinstall-downloader.sh
fi

if [ -f /var/run/lesslinux/flashinstall/flash11.tgz ] ; then
	mkdir -p ${HOME}/.mozilla/plugins 
	tar -C  ${HOME}/.mozilla/plugins -xzf /var/run/lesslinux/flashinstall/flash11.tgz libflashplayer.so
	for p in $paths ; do
		mkdir -p ${HOME}/.mozilla/firefox/${p}/plugins
		ln -sf ${HOME}/.mozilla/plugins/libflashplayer.so ${HOME}/.mozilla/firefox/${p}/plugins/libflashplayer.so
	done
	rm ${HOME}/Desktop/flashinstall.desktop
	zenity --info --text "$success_msg"
else
	# zenity --error --text "$error_msg"
	exit 1
fi
