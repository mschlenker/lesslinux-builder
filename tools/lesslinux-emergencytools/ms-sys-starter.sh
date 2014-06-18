#!/static/bin/ash

if check_lax_sudo ; then
	sudo /usr/bin/ms-sys-starter.rb
else
	/usr/bin/llaskpass-mount.rb | sudo -S /usr/bin/ms-sys-starter.rb
fi
