#!/static/bin/ash

if check_lax_sudo ; then
	sudo /usr/bin/dc3dd-starter.rb
else
	/usr/bin/llaskpass-mount.rb | sudo -S /usr/bin/dc3dd-starter.rb
fi
