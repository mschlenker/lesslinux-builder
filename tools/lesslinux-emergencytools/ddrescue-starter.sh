#!/static/bin/ash


if check_lax_sudo ; then
	sudo /usr/bin/ddrescue-starter.rb
else
	/usr/bin/llaskpass-mount.rb | sudo -S /usr/bin/ddrescue-starter.rb
fi
