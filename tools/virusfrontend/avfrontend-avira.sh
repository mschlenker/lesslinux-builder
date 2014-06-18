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
nmessage='The directory /AntiVir is missing, this most probably means that Avira is currently not installed. To install, download the ISO image from http://www.avira.com/de/support-download-avira-antivir-rescue-system and place it in the folder lesslinux/blob of your live system. CDs/DVDs have to be remastered of course.'
ntitle='Avira not found'

if [ "$lang" = "de" ] ; then
	zmessage='Die Virensignaturen wurden heute noch nicht aktualisiert. Bitte stellen Sie sicher, dass eine Verbindung ins Internet existiert und klicken Sie dann "OK" um die Signaturen zu aktualisieren.'
	ztitle='Update der Virensignaturen'
	nmessage='Das Verzeichnis /AntiVir fehlt, vermutlich ist Avira nicht installiert. Um es zu installieren, laden Sie das ISO-Image von http://www.avira.com/de/support-download-avira-antivir-rescue-system herunter und speichern Sie es im Ordner lesslinux/blob Ihres Live-Systems. CDs/DVDs müssen hierfür remastert werden.'
	ntitle='Avira nicht gefunden'
elif [ "$lang" = "pl" ] ; then
	zmessage='Baza sygnatur wirusów nie została dziś uaktualniona. Proszę upewnić się, że połączenie z internetem działa i kliknąć na przycisk OK, aby przeprowadzić procedurę aktualizacji baz sygnatur wirusów.'
	ztitle='Aktualizacja baz sygnatur wirusów'
fi

if [ '!' -d "/AntiVir" ] ; then
	zenity --error --title "$ntitle" --text "$nmessage"
	exit 1
fi

today=` date '+%Y%m%d' `
if [ -f "/tmp/avira-update-${today}.nul" ] ; then
	echo "Skipping update of Avira signatures"
else
	zenity --question --title "$ztitle" --text "$zmessage" && Terminal --geometry=80x25 --hide-toolbar --hide-menubar --disable-server -T "$ztitle" -x sudo /AntiVirUpdate/avupdate && touch "/tmp/avira-update-${today}.nul"
fi

# Now enter our program directory and startup the GUI

cd /usr/share/lesslinux/avfrontend

cfgfile=avira.xml

if [ -f "avira.$lang.xml" ] ; then
	cfgfile="avira.$lang.xml"
fi

sudo ./virusfrontend --config "$cfgfile"
