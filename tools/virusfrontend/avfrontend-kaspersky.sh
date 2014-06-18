#!/bin/bash

# Update the signatures

PATH=$PATH:/opt/kaspersky/kav4ws/bin/
export PATH

today=` date '+%Y%m%d' `
if [ -f "/var/run/lesslinux/kaspersky-update-${today}.nul" ] ; then
	echo "Skipping update of Kaspersky signatures"
else
	zenity --question --title 'Update der Virensignaturen' --text 'Die Virensignaturen wurden heute noch nicht aktualisiert. Bitte stellen Sie sicher, dass eine Verbindung ins Internet existiert und klicken Sie dann "OK" um die Signaturen zu aktualisieren.' && Terminal --geometry=80x25 --hide-toolbar --hide-menubar --disable-server -T "Update der Virensignaturen" -x sudo kav4ws-keepup2date && touch "/tmp/kaspersky-update-${today}.nul"
fi

# Now enter our program directory and startup the GUI

cd /usr/share/lesslinux/avfrontend
sudo ./virusfrontend --config kaspersky.xml
