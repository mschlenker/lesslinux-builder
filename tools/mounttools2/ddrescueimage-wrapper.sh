#!/bin/bash
# encoding: utf-8

# $1 input
# $2 output
# $3 run

if [ "$3" -lt 2 ] ; then
	/usr/bin/ddrescue --sparse -n "$1" "$2" "${2}.log"
	retval=$?
	echo -n $retval > "${2}.exit"
else
	/usr/bin/ddrescue --sparse -r 5 "$1" "$2" "${2}.log"	
	sleep 5
fi
