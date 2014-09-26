#!/bin/bash
# encoding: utf-8

if [ -f /var/run/initial_check.done ] ; then
	echo 'Skipping check...'
else
	ruby -I /usr/share/lesslinux/drivetools /usr/share/lesslinux/drivetools/initial_system_check.rb 
	touch /var/run/initial_check.done
fi
