#!/bin/bash

ppversion=0.7.2
oinkcode=` cat /lesslinux/blobpart/snort/oinkcode.txt `
ppconf=etc/pulledpork.lesslinux.conf
snortvers=29110

# Download and install pulledpork
if [ -d /lesslinux/blobpart/snort/pulledpork-${ppversion} ] ; then
	echo "Found Pulledpork, skipping download"
else
	wget -O - https://github.com/shirkdog/pulledpork/archive/v${ppversion}.tar.gz | tar -C /lesslinux/blobpart/snort -xzf - 
fi
if [ -d /lesslinux/blobpart/snort/pulledpork-${ppversion} ] ; then
	echo "Found Pulledpork, continuing"
	if [ -L /lesslinux/blobpart/snort/pulledpork ] ; then
		echo "Found Pulledpork softlink"
	else
		ln -s pulledpork-${ppversion} /lesslinux/blobpart/snort/pulledpork
		rm /lesslinux/blobpart/snort/pulledpork/etc/pulledpork.conf 
	fi
else
	exit 1
fi

# Download and install first signatures 
if [ -f /etc/snort/etc/snort.conf ] ; then
	echo "First signature package seems to be downloaded" 
else
	wget -O - 'https://www.snort.org/rules/snortrules-snapshot-${snortvers}.tar.gz?oinkcode='${oinkcode}  | tar -C /etc/snort -xzf - 
	if [ -f /etc/snort/etc/snort.conf ] ; then
		install -m 0644 /etc/snort.dist/snort.conf /etc/snort/etc/snort.conf 
	else
		exit 1
	fi
fi

# Create lesslinux specific configuration
cat /etc/snort.dist/pulledpork.conf | sed 's/OINKCODE/'${oinkcode}'/g' > /lesslinux/blobpart/snort/pulledpork/etc/pulledpork.lesslinux.conf
[ -f  /lesslinux/blobpart/snort/pulledpork/etc/pulledpork.conf ] && ppconf=etc/pulledpork.conf

# Run pulledpork 
cd /lesslinux/blobpart/snort/pulledpork
perl pulledpork.pl -c "${ppconf}" -i etc/disablesid.conf -T -H -d -w || exit 1 
touch /lesslinux/blobpart/snort/pulledpork_last_success

