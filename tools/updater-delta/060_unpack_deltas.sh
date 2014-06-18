#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/static/bin:/static/sbin

. ./common_vars.sh

cat chunk02.??  | ( cd /lesslinux/cdrom/lesslinux && tar xvf - )
