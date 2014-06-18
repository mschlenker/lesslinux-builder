#!/bin/bash
# encoding: utf-8
# Update the signatures

PATH=$PATH:/opt/bin/
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/lib/
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

zmessage='The virus signatures were not yet updated today. Please make sure that an internet connection exists and then click "OK" to start the signature update.'
ztitle='Updating virus signatures'

if [ "$lang" = "de" ] ; then
	zmessage='Die Virensignaturen wurden heute noch nicht aktualisiert. Bitte stellen Sie sicher, dass eine Verbindung ins Internet existiert und klicken Sie dann "OK" um die Signaturen zu aktualisieren.'
	ztitle='Update der Virensignaturen'
elif [ "$lang" = "pl" ] ; then
	zmessage='Baza sygnatur wirusów nie została dziś uaktualniona. Proszę upewnić się, że połączenie z internetem działa i kliknąć na przycisk OK, aby przeprowadzić procedurę aktualizacji baz sygnatur wirusów.'
	ztitle='Aktualizacja baz sygnatur wirusów'
fi

# Check for mounted drives at /media/disk

cd /usr/share/lesslinux/avfrontend
sudo /usr/share/lesslinux/avfrontend/avpremount.sh

today=` date '+%Y%m%d' `
if [ -f "/tmp/clamav-update-${today}.nul" ] ; then
	echo "Skipping update of ClamAV signatures"
else
	zenity --question --title "$ztitle" --text "$zmessage" && Terminal --geometry=80x25 --hide-toolbar --hide-menubar --disable-server -T "$ztitle" -x sudo /opt/bin/freshclam && touch "/tmp/clamav-update-${today}.nul"
fi

# Now enter our program directory and startup the GUI

cfgfile=clamav.xml

if [ -f "clamav.$lang.xml" ] ; then
	cfgfile="clamav.$lang.xml"
fi

sudo ./virusfrontend --config "$cfgfile"
