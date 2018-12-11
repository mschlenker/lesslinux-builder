#!/bin/bash
# encoding: utf-8

# Wrapper script for ESET virus scan
# As non free component ESETs squashfs image is needed

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh

ruby /usr/share/lesslinux/drivetools/waitservice.rb eset 

esnotfound="Could not find ESETs filesystem image - make sure you have an internet connection to start the installation now."
[ $lang = de ] && esnotfound="Konnte ESETs Dateisystem-Image nicht finden - Stellen Sie bitte sicher, dass Sie über eine Internetverbindung verfügen, um die Installation jetzt zu starten."

if [ '!' -x "/opt/eset/esets/sbin/esets_daemon" ] ; then
	zenity --error --text "$esnotfound" 
	sudo /usr/bin/blobinstall.sh --check eset
fi

( cd /usr/share/lesslinux/avfrontend ; sudo /usr/share/lesslinux/avfrontend/avpremount.sh ) 

sleep 2
sudo /opt/eset/esets/bin/esets_gui
