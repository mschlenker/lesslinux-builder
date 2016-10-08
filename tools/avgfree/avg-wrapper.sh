#!/bin/bash
# encoding: utf-8

if [ -x /opt/avg/av/bin/avgscan ] ; then
	echo "OK, continue..."
else
	zenity --info --text "Der AVG-Virenscanner wurde nicht gefunden. Um ihn jetzt zu installieren stellen Sie sicher, dass eine Internetverbindung besteht. Der Downloadumfang beträgt ca. 130MB." --width=800 
	blobinstall.sh --check avg-free --hide chrome,teamviewer
fi

if [ ` cat /proc/mounts | awk '{print $2}' | grep '^/media/disk/' | wc -l ` -lt 1 ] ; then
	/usr/share/lesslinux/avfrontend/avpremount.sh
fi

if [ -x /opt/avg/av/bin/avgscan ] ; then
	echo "OK, continue..."
	/usr/share/lesslinux/avgfree/avg-gui.sh
else
	zenity --info --text "Der AVG-Virenscanner wurde nicht gefunden. Es wird nun ein Virenscan mit ClamAV durchgeführt. Bitte beachten Sie, dass ClamAV zu Fehlalarmen neigt. Ob es sich bei identifizierten Dateien um Schadsoftware handelt, können Sie mit Webdiensten wie virustotal.com nachprüfen." --width=800 
	/usr/bin/avfrontend-clamav.sh
fi
