#!/bin/bash
# encoding: utf-8

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams

# New script

if [ -x /usr/bin/ruby -a -d /usr/share/lesslinux/drivetools ] ; then
	cd /usr/share/lesslinux/shutdown-dummy
	ruby -I . -I /usr/share/lesslinux/drivetools shutdown-dummy.rb 
	exit 0
fi

# Old script

msg="Do you want to shutdown the computer?"
[ "$lang" = "de" ] && msg="Wollen Sie den Computer ausschalten?" 
[ "$lang" = "pl" ] && msg="Czy na pewno chcesz wyłączyć komputer?" 

zenity --question --text "$msg" || exit 1

[ "$console" = tty2 ] && chvt 2 

if [ "$halt" = "poweroff" ] ; then 
	sudo /sbin/poweroff
else
	sudo /sbin/halt
fi
