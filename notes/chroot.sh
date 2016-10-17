#!/bin/sh

srcdir=/mnt/archiv/LessLinux/src

action="$1"
directory="$2"
isoimage="$3"

[ -z "$action" ] && echo "Please specify an action: prepare or unset"
[ -z "$directory" ] && echo "Please specify a directory"

# If three arguments are given, threat the third as path to the iso image
# and mount it loopback

case $action in 
	prepare)
		if [ -n "$isoimage" ] ; then
			mkdir -p "${directory%/}.loop"
			mount -o loop "$isoimage" "${directory%/}.loop" || exit 1
			for d in lib bin sbin usr opt ; do
				mkdir -p "${directory}/${d}"
				mount -o loop "${directory%/}.loop/lesslinux/${d}.sqs" "${directory}/${d}" 
			done
			mkdir -p "${directory}/usr/bin"
			mount -o loop "${directory%/}.loop/lesslinux/usrbin.sqs" "${directory}/usr/bin"
		fi
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
		mountpoint -q "${directory}/usr/bin" && umount "${directory}/usr/bin"
		for d in lib bin sbin usr opt ; do
			mountpoint -q "${directory}/${d}" && umount "${directory}/${d}"
		done
		mountpoint -q "${directory%/}.loop" && umount "${directory%/}.loop"
	;;
esac
