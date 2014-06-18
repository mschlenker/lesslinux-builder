#!/bin/bash

. ./common_vars.sh

modloop=` mount | grep ' /lib/modules/2' | awk '{print $1}' ` 
umount /lib/modules/` uname -r `
losetup -d $modloop
