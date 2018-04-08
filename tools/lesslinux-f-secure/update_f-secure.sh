#!/bin/bash

# (c) 2016-2018 Mattias Schlenker

function update_running {
	procs=`ps waux | awk '{print $12}' `
	grep dbupdate_lite "$procs" > /dev/null && return 0
	return 1
}

# FIXME: Make sure everything is mounted first!

lang=de
tstyle='+%d.%m.%Y_%H:%M'
case $LANG in 
	nl*)
		lang=nl
		tstyle='+%d-%m-%Y_%H:%M'
	;;
esac

clear

today=` date "+%Y%m%d" ` 
mkdir -p /var/run/lesslinux
echo 666 > /var/run/lesslinux/update_f-secure_returncode
/etc/init.d/fsaua status
( sleep 30 ; /etc/init.d/fsaua start ) & 
/opt/f-secure/fssp/bin/dbupdate_lite 
sleep 10
( sleep 30 ; /etc/init.d/fsaua start ) & 
/opt/f-secure/fssp/bin/dbupdate_lite
ret="$?"

echo "$ret" > /var/run/lesslinux/update_f-secure_returncode
if [ "$ret" -lt 1 ] ; then
	touch /var/run/lesslinux/skip_f-secure_update_${today}
fi
