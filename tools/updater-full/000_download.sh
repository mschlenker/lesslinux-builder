#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/static/bin:/static/sbin

. ./common_vars.sh
# echo "Downloading $1"
echo "Downloading: http://download.lesslinux.org/updater/${this_version}/${1}"
echo internet > /proc/self/attr/current
wget -O - "http://download.lesslinux.org/updater/${this_version}/${1}" >> "${2}/update.iso"
echo _ > /proc/self/attr/current
