#!/bin/bash
# encoding: utf-8

# $1 input
# $2 output
# $3 run

if [ "$3" -eq 1 ] ; then
	# echo "Run 1"
	/usr/bin/ddrescue --sparse -n "$1" "$2" "${2}.log"
	retval=$?
	echo -n $retval > "${2}.exit"
else
	# echo "Run 2"
	/usr/bin/ddrescue --sparse -r 5 "$1" "$2" "${2}.log"	
	sleep 3
fi
