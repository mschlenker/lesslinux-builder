#!/bin/bash

openvas-nvt-sync || openvas-nvt-sync

# Write config
mkdir -p /etc/openvas
cat > /etc/openvas/redis.conf <<EOF
daemonize yes
bind 127.0.0.1
unixsocket /tmp/redis.sock
unixsocketperm 700
EOF

# Start the scan daemon
openvassd -p 9391 -a 127.0.0.1

# Rebuild the database
# test -f /usr/var/lib/openvas/mgr/tasks.db || openvasmd --rebuild
echo 'Rebuilding the database - this might take some time!'
openvasmd --rebuild

# test -f /usr/var/lib/openvas/scap-data/scap.db || openvas-scapdata-sync 
openvas-scapdata-sync || openvas-scapdata-sync

# test -f /usr/var/lib/openvas/cert-data/cert.db || openvas-certdata-sync
openvas-certdata-sync || openvas-certdata-sync

openvasmd -p 9390 -a 127.0.0.1
openvasmd --create-user=lesslinux --role=Admin
openvasmd --user=lesslinux --new-password=lesslinux
gsad --http-only --listen=127.0.0.1 -p 9392 

# nohup su surfer -c 'firefox http://127.0.0.1:9392/' &
