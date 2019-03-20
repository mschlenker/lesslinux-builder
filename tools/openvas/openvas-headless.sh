#!/bin/bash
ruby /usr/share/lesslinux/drivetools/waitservice.rb openvas 

greenbone-nvt-sync || greenbone-nvt-sync
greenbone-scapdata-sync || greenbone-scapdata-sync
greenbone-certdata-sync || greenbone-certdata-sync

# Write config
mkdir -p /etc/openvas
cat > /etc/openvas/redis.conf <<EOF
daemonize yes
bind 127.0.0.1
unixsocket /tmp/redis.sock
unixsocketperm 700
EOF

redis-server /etc/openvas/redis.conf


# Start the scan daemon
openvassd 
sleep 1
plist=`ps waux  | awk '{print $11}' ` 
if echo "$plist" | grep openvassd ; then
	echo "Successfully started openvassd"
else
	echo "Starting openvassd"
	openvassd
	sleep 1
fi

# Rebuild the database
# test -f /usr/var/lib/openvas/mgr/tasks.db || openvasmd --rebuild
echo 'Rebuilding the database - this might take some time!'
openvasmd --rebuild --progress
openvasmd --create-user=lesslinux --role=Admin
openvasmd --user=lesslinux --new-password=lesslinux
sleep 1
openvasmd 
sleep 1
plist=`ps waux  | awk '{print $11}' ` 
if echo "$plist" | grep openvasmd ; then
	echo "Successfully started openvasmd"
else
	echo "Starting openvasmd"
	openvasmd 
	sleep 1
fi

gsad --http-only --listen=127.0.0.1 -p 9392 start
