#!/bin/bash

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/static/bin:/static/sbin

. ./common_vars.sh

cat chunk03.??  | ( cd /lesslinux/cdrom && tar xvjf - )
