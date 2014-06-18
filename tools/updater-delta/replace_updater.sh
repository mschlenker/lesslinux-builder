#!/static/bin/ash

if  zenity --warning --text='Sie müssen den Computer neu starten, um die begonnene Aktualisierung abzuschließen. Soll der Computer jetzt neu gestartet werden?' ; then
	echo 'reboot requested'
	/sbin/reboot
else
	echo 'reboot cancelled'
fi
