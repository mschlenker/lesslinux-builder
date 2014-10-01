#!/bin/bash

# (c) 2014 Mattias Schlenker for LessLinux

ask_for_quit() {
	task="$1"
	echo -n "${task} failed - continue anyway? [y/N] "
	read continue
	case "$continue" in 
		[yYjJ]*)
			echo 'OK, continue...'
		;;
		*)
			echo "${task} failed - exiting."
			exit 1
		;;
	esac
}

me=` id -u `
if [ "$me" -gt 0 ] ; then
        echo 'Please run this script with root privileges!'
fi

if mountpoint -q /lesslinux/blobpart ; then
	echo '/lesslinux/blobpart is mounted, great...'
else
	echo 'WARNING: You are currently running from memory!'
	echo ''
	echo 'OpenVAS large collection of vulnerability tests needs more than 1.5GB space.'
	echo 'You might continue if you have at least 6GB of RAM. If you have less main'
	echo 'memory or wish to keep the data persistent, please read the notes on creating'
	echo 'a bootable USB thumb drive or a thumb drive just containing OpenVAS data.'
	echo ''
	echo 'More information: http://blog.lesslinux.org/openvas-included/'
	echo ''
	ask_for_quit "BLOB partition"
fi

openvas-nvt-sync || openvas-nvt-sync
retval=$?
[ "$retval" -gt 0 ] && ask_for_quit "Syncing NVT"

# Start the scan daemon
openvassd -p 9391 -a 127.0.0.1

# Rebuild the database
# test -f /usr/var/lib/openvas/mgr/tasks.db || openvasmd --rebuild
echo 'Rebuilding the database - this might take some time!'
openvasmd --rebuild

# test -f /usr/var/lib/openvas/scap-data/scap.db || openvas-scapdata-sync 
openvas-scapdata-sync || openvas-scapdata-sync
retval=$?
[ "$retval" -gt 0 ] && ask_for_quit "Syncing Scapdata"

# test -f /usr/var/lib/openvas/cert-data/cert.db || openvas-certdata-sync
openvas-certdata-sync || openvas-certdata-sync
retval=$?
[ "$retval" -gt 0 ] && ask_for_quit "Syncing CERT data"

openvasmd -p 9390 -a 127.0.0.1
openvasmd --create-user=lesslinux --role=Admin
openvasmd --user=lesslinux --new-password=lesslinux
gsad --http-only --listen=127.0.0.1 -p 9392 

echo 'Starting Firefox - login with username "lesslinux" and password "lesslinux"!'
zenity --info --text 'Starting Firefox - login with username "lesslinux" and password "lesslinux"!'

nohup su surfer -c 'firefox http://127.0.0.1:9392/' &
