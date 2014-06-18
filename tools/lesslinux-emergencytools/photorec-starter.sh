#!/static/bin/ash

if check_lax_sudo ; then
	sudo /usr/bin/photorec-starter.rb
else
	/usr/bin/llaskpass-mount.rb | sudo -S /usr/bin/photorec-starter.rb
fi
