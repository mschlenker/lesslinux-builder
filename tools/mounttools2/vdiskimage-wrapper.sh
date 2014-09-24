#!/bin/bash
# encoding: utf-8

# $1 format
# $2 input
# $3 output

/usr/bin/qemu-img convert -f raw -O "$1" "$2" "$3"
retval=$?
echo -n $retval > "${3}.exit"
