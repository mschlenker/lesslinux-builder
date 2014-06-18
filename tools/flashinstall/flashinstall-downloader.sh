#!/bin/bash
# encoding: utf-8
	
. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

flash_download_failed="Failed downloading the Flash plugin."
flash_signature_failed="Signature check of the flash plugin failed."
flash_downloading="Downloading Flash..."

if [ "$lang" = "de" ] ; then
	flash_download_failed="Das Herunterladen des Flash-Plugins ist fehlgeschlagen."
	flash_signature_failed="Die Signatur des Flash-Plugins konnte nicht verifiziert werden. Flash wird nicht installiert."
	flash_downloading="Lade Flash herunter..."
fi

mkdir -p /var/run/lesslinux/flashinstall
chmod 0700 /var/run/lesslinux/flashinstall

for fname in flash11.tgz flash11.tgz.asc ; do
    echo netmgr > /proc/self/attr/current
    # Since we validate afterwards, do not check certificates
    (echo "test" ; /usr/bin/wget --no-check-certificate -U LessLinuxFlashDownload -O /var/run/lesslinux/flashinstall/${fname} "http://download.lesslinux.org/3rdparty/${fname}" ) \
	| zenity --pulsate --no-cancel --auto-close --progress --text "$flash_downloading"
    retval=$?
    echo _ > /proc/self/attr/current
    if [ "$retval" -gt 0 ] ; then	
	/usr/bin/zenity --error --text "$flash_download_failed"
	exit 1
    fi
done

# Importiere the key
/usr/bin/gpg --import /etc/lesslinux/updater/updatekey.asc

# Prüfung der Signatur
if /usr/bin/gpg --verify /var/run/lesslinux/flashinstall/flash11.tgz.asc ; then
	echo "===> Signatur OK, fahre fort"
	chmod 0755 /var/run/lesslinux/flashinstall
else
	/usr/bin/zenity --error --text "$flash_signature_failed"
	exit 1
fi
