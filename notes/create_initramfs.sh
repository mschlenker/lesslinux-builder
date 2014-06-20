#!/bin/bash
# $1: Directory
# $2: Output file

wdir="$1"
ofile="$2"
comp="$3"
[ -z "$comp" ] && comp="gzip" 

cd "$wdir" || exit 1
find . | cpio -o -H newc | "$comp" -c > "$ofile" 

