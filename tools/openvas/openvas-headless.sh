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

# Rebuild the database
# test -f /usr/var/lib/openvas/mgr/tasks.db || openvasmd --rebuild
echo 'Rebuilding the database - this might take some time!'
openvasmd --rebuild --progress
openvasmd --create-user=lesslinux --role=Admin
openvasmd --user=lesslinux --new-password=lesslinux
openvasmd 

gsad --http-only --listen=127.0.0.1 -p 9392 start
