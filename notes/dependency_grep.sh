#!/bin/bash
depfile=$1
[ -z "$1" ] && exit 1 
grep ^hard "$depfile" | awk '{print "                        <dep>"$2"</dep>"}' | sort | ( echo '               <builddeps>' ; uniq ; echo '                </builddeps>'; )
