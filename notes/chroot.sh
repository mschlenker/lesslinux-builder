#!/bin/sh

srcdir=/mnt/archiv/LessLinux/src

action=$1
directory=$2
[ -z "$action" ] && echo "Please specify an action: prepare or unset"
[ -z "$directory" ] && echo "Please specify a directory"

case $action in 
	prepare)
		for i in dev proc dev/pts sys tmp ; do
			mountpoint -q "${directory}/$i" || mount --bind /$i "${directory}/$i"
		done
		mkdir -p "${directory}/tmp/src"
		mountpoint -q "${directory}/tmp/src" || mount --bind "${srcdir}" "${directory}/tmp/src"
	;;
	unset)
		umount "${directory}/tmp/src" 
		for i in dev/pts proc dev sys tmp ; do
			umount "${directory}/$i"
		done
	;;
esac
