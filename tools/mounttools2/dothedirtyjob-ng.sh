#!/bin/bash

. /etc/lesslinux/branding/branding.en.sh
. /etc/rc.subr/extractbootparams

device="/dev/$1"
lang="$2"
# homecontmax=0
#swapsize=2048
#blobsize=3072
tempdev=` uuidgen `
#lang=de
	
syssourcedir=/lesslinux/cdrom
mountpoint -q /lesslinux/isoloop && syssourcedir=/lesslinux/isoloop 
	
# Size of boot/isolinux directory in kilobytes
bootsize=` du -sk ${syssourcedir}/boot | awk '{print $1}' `
# echo "bootsize: $bootsize"

# Size of boot partition in count of 8MB blocks - roughly add 50% for updates
bootblocks=` expr $bootsize / 5461 + 1 ` 
# echo "bootblocks: $bootblocks"	

# Size of ISO image in kilobytes
isosize=` df -k | grep "${syssourcedir}" | awk '{print $3}' `
# Size of ISO partition in count of 8MB blocks - roughly add 25% for updates
isoblocks=` expr $isosize / 6553 + 1 ` 
isombblocks=` expr $isosize / 1024 + 3 ` 
# echo "$isoblocks: $isoblocks"

# Run dd 
dd if=` cat /var/run/lesslinux/install_source ` of=${device} bs=1M count=${isombblocks} || exit 1 
sync 

# echo "Isoblocks: $isoblocks"
# Size of device in kilobyte blocks
shortdev=` echo -n $device | sed 's%/dev/%%g' ` 
devicesize=` cat /proc/partitions | grep "$shortdev"'$' | awk '{print $3}' ` 
# Size of device in 8MB blocks - there might be little bit less than 8MB left out
deviceblocks=` expr $devicesize / 8192 ` 
# echo "Deviceblocks: $deviceblocks"
hcminblocks=0
hcmaxblocks=0 
if [ "$homecontmax" -gt 0 ] ; then
	hcmaxblocks=` expr $homecontmax / 8 ` 
	hcminblocks=` expr $homecontmin / 8 ` 
fi
# blobblocks 
blobblocks=0
if [ "$blobsize" -gt 63 ] ; then
	blobblocks=` expr $blobsize / 8 ` 
else
	blobblocks=1
fi
# Swap size
swapblocks=0
if [ "$swapsize" -gt 63 ] ; then
	swapblocks=` expr $swapsize / 8 ` 
else
	swapblocks=1
fi
# Now check for minimum free space - FIXME: 128MB are not good to be hard coded
neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $efiblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
# echo "Neededblocks: $neededblocks"
if [ "$deviceblocks" -lt "$neededblocks" ] ; then
	# Try without swap:
	swapblocks=1
	neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $efiblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
	if [ "$deviceblocks" -lt "$neededblocks" ] ; then
		hcminblocks=0
		hcmaxblocks=0 
		neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $efiblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
		if [ "$deviceblocks" -lt "$neededblocks" ] ; then
			echo "===> FAILED. Device too small."
			exit 1
		fi
	fi
fi
	
# Delete some MB at the end of the disk to remove remaining GUID backup table
dd if=/dev/zero of=$device bs=8388608 seek=` expr $deviceblocks - 4 ` 2>/dev/null
	
echo '===> Creating partition table for'" $device"
	
# Recalculate the possible size of the partition for the encrypted home container
hcblocks=1
if [ "$homecontmax" -gt 0 ] ; then
	hcmaxblocks=` expr $homecontmax / 8 ` 
	hcminblocks=` expr $homecontmin / 8 ` 
	hcpossible=` expr $deviceblocks - $isoblocks - $isoblocks - $bootblocks - $blobblocks - $swapblocks - 40 ` 
	if [ "$hcpossible" -gt $hcmaxblocks ] ; then
		hcblocks=$hcmaxblocks
	else
		hcblocks=$hcpossible
	fi
fi

# Create a single FAT32 partition holding legacy and EFI boot files
freespacestart=` expr '(' $deviceblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - 2 ')' '*' 8388608 `
partstart=`      expr '(' $isoblocks + 2 ')' '*' 8388608 `
# Now overwrite the start of the device
dd if=/dev/zero bs=512 count=1 of="$device"
parted -s $device unit B mklabel msdos
dd if=/etc/syslinux/mbr.bin bs=440 count=1 of="$device"
sync
# Single partition - data, legacy boot, EFI boot
parted -s $device unit B mkpart primary fat32 $partstart ` expr $freespacestart - 1 `  
parted -s $device unit B set 1 boot on
parted -s $device unit B set 1 esp on
sync 
sleep 10 

# Wait up to two minutes for device to appear:

searchcount=0
[ -b ${device}1 ] || echo "Waiting for device ${device}1" 
while [ "$searchcount" -lt 120 ] ; do
	if [ -b ${device}1 ] ; then
		echo -n ':'
	else
		echo -n '.'
		sleep 1
	fi
	searchcount=$(( $searchcount + 1 )) 
done

[ -b ${device}1 ] || exit 1 
echo ':'
[ -b ${device}1 ] && dd if=/dev/zero bs=1M count=8 of=${device}1

mkfs.msdos -F 32 -n USBDATA "${device}1" || exit 1 
sync 
newuuid=` blkid -o udev "${device}1" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 

mkdir -p /tmp/batchinstall/${tempdev}/boot
mount -t vfat -o rw "${device}1" /tmp/batchinstall/${tempdev}/boot || exit 1 
mkdir -p /tmp/batchinstall/${tempdev}/boot/boot
touch /tmp/batchinstall/${tempdev}/boot/boot/dontconvert

# Copy legacy boot files
tar -C ${syssourcedir} -cvf - boot | tar -C /tmp/batchinstall/${tempdev}/boot/ -xf -
sync
touch /tmp/batchinstall/${tempdev}/boot/cmdline
# Copy GRUBs file to properly detect the boot partition
idfile=` ls /tmp/batchinstall/${tempdev}/boot/boot/grub/????????.cd `
idtarg=` echo $idfile | sed 's/\.cd/.pt/g' ` 
mv $idfile $idtarg

if mountpoint /tmp/batchinstall/efiloop ; then
	echo "Efiloop already mounted..."
else
	efiloop=` losetup -f `
	mkdir -p /tmp/batchinstall/efiloop 
	losetup $efiloop ${syssourcedir}/boot/efi/efi.img
	mount -t vfat -o ro $efiloop /tmp/batchinstall/efiloop
fi

tar -C /tmp/batchinstall/efiloop -cvf - . | tar -C /tmp/batchinstall/${tempdev}/boot/ -xf -
sync
# Modify EFI boot files
find /tmp/batchinstall/${tempdev}/boot/loader -type f -name '*.usb' | while read cfgfile ; do 
	outfile=` echo ${cfgfile} | sed 's/\.usb$/.conf/g' `
	cp -v ${cfgfile} ${outfile} 
done
#find /tmp/batchinstall/${tempdev}/boot/loader -type f -name '*.conf' | while read cfgfile ; do 
#	[ -f "${cfgfile}.${lang}" ] && cp "${cfgfile}.${lang}" "${cfgfile}"
#	sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
#	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
#	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
#	[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
#done

# Modify legacy boot files
find /tmp/batchinstall/${tempdev}/boot/boot/isolinux -type f -name '*.cfg' | while read cfgfile ; do 
	[ -f "${cfgfile}.${lang}" ] && cp "${cfgfile}.${lang}" "${cfgfile}"
	sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
	[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
	sed -i 's%^INCLUDE /boot/isolinux/boot0x80.cfg%# INCLUDE /boot/isolinux/boot0x80.cfg%g' "${cfgfile}"
	sed -i 's%^INCLUDE /boot/isolinux/\([a-z]*\)/boot0x80.cfg%# INCLUDE /boot/isolinux/\1/boot0x80.cfg%g' "${cfgfile}"
	sed -i 's%^MENU INCLUDE /boot/isolinux/\([a-z]*\)/boot0x80.cfg%# MENU INCLUDE /boot/isolinux/\1/boot0x80.cfg%g' "${cfgfile}"
	sed -i 's%^# INCLUDE /boot/isolinux/usbonly%INCLUDE /boot/isolinux/usbonly%g' "${cfgfile}" 
	sed -i 's%^# INCLUDE /boot/isolinux/\([a-z]*\)/usbonly%INCLUDE /boot/isolinux/\1/usbonly%g' "${cfgfile}" 
	sed -i 's%^# MENU INCLUDE /boot/isolinux/\([a-z]*\)/usbonly% MENU INCLUDE /boot/isolinux/\1/usbonly%g' "${cfgfile}" 
done
cfg=/tmp/batchinstall/${tempdev}/boot/boot/isolinux/isolinux.cfg
[ -f /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf ] && cfg=/tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf
[ -f /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf.${lang} ] && cfg=/tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf.${lang}
[ -f /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.cfg ] && cfg=/tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.cfg
[ "$cfg" '!=' /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf ] && cp "$cfg" /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf
sed -i 's/uuid=all/uuid='"${newuuid}"'/g' /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf
#[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  /tmp/batchinstall/${tempdev}/boot/isolinux/extlinux.conf
#[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' /tmp/batchinstall/${tempdev}/boot/isolinux/extlinux.conf
#[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    /tmp/batchinstall/${tempdev}/boot/isolinux/extlinux.conf

if [ -f /lesslinux/cdrom/boot/kickstart.xd3 ]  ; then
	#for f in ` grep 'i.*\.gz'  /tmp/batchinstall/${tempdev}/efiboot/efi.sha | awk '{print $2}' `; do
	#	cat /tmp/batchinstall/${tempdev}/efiboot/${f} >> /tmp/batchinstall/${tempdev}/data/kickstart.raw
	#done
	for f in ` cat /lesslinux/cdrom/lesslinux/boot.sha | awk '{print $2}' `; do
		cat /lesslinux/cdrom/boot/kernel/${f} >> /tmp/batchinstall/${tempdev}/boot/kickstart.raw
	done
	xdelta3 -d -s /tmp/batchinstall/${tempdev}/boot/kickstart.raw /lesslinux/cdrom/boot/kickstart.xd3 \
		/tmp/batchinstall/${tempdev}/boot/kickstart.iso
	ls -lah /tmp/batchinstall/${tempdev}/boot/kickstart.iso 
	rm /tmp/batchinstall/${tempdev}/boot/kickstart.raw
fi

tar -C /lesslinux/cdrom -cf - Manual autorun.usb GPL.txt license | tar -C  /tmp/batchinstall/${tempdev}/boot -xvf -
mv /tmp/batchinstall/${tempdev}/boot/autorun.usb /tmp/batchinstall/${tempdev}/boot/autorun.inf
if [ -f /etc/lesslinux/branding/extrafiles.txt ] ; then
	for fname in ` cat /etc/lesslinux/branding/extrafiles.txt `] ; do
		tar -C /lesslinux/cdrom -cf - $fname | tar -C  /tmp/batchinstall/${tempdev}/boot -xvf - 
	done
fi
if [ -f /etc/lesslinux/branding/usbpostinstall.sh ] ; then
	bash /etc/lesslinux/branding/usbpostinstall.sh /tmp/batchinstall/${tempdev}/boot
fi

echo -n "${newuuid}" > /tmp/batchinstall/${tempdev}/boot/boot/boot.uuid
extlinux --install /tmp/batchinstall/${tempdev}/boot/boot/isolinux
umount /tmp/batchinstall/${tempdev}/boot/
sync 

# Check if there is enough space behind the partition table for another ISO image
devsize=`     parted -m -s ${device} unit b print | grep msdos | awk -F ':|B:' '{print $2}' ` 
partend=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $3}'  `
isosize=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $2}'  `
isotwostart=` expr $devsize - $isosize - 8388608 ` 
# Exit gracefully if size is not sufficient
[ "$isotwostart" -lt "$partend" ] && exit 0
# Determine the end of our new loop device by matching an 8M chunk towards the end of the device: 
loopendblock=` expr '(' $devsize - $isosize ')' / 8388608 - 1 ` 
# Create a loop device with correct parameters 
freeloop=` losetup -f ` 
losetup -o ` expr $partend + 1 ` --sizelimit ` expr $loopendblock '*' 8388608 - $partend - 1 ` $freeloop $device
dd if=/dev/zero bs=1M count=8 of=${freeloop} 
# Calculate numbers of blocks needed:
# BLOB first
blobblocks=0
if [ "$blobsize" -gt 63 ] ; then
	blobblocks=` expr $blobsize / 8 ` 
else
	blobblocks=1
fi
# Swap size
swapblocks=0
if [ "$swapsize" -gt 63 ] ; then
	swapblocks=` expr $swapsize / 8 ` 
else
	swapblocks=1
fi
# encrypted home
# Recalculate the possible size of the partition for the encrypted home container
loopblocks=` expr $loopendblock - '(' $partend / 8388608 ')' ` 
hcblocks=1
if [ "$homecontmax" -gt 0 ] ; then
	hcmaxblocks=` expr $homecontmax / 8 ` 
	hcminblocks=` expr $homecontmin / 8 ` 
	hcpossible=` expr $loopblocks - $blobblocks - $swapblocks ` 
	if [ "$hcpossible" -gt $hcmaxblocks ] ; then
		hcblocks=$hcmaxblocks
	else
		hcblocks=$hcpossible
	fi
fi
	
# Create partition table: 
parted -s "$freeloop" mklabel gpt
	
# First partition - Swap
swappartlabel="${brandshort}-SWAP"
[ "$swapblocks" -lt 32 ] && swappartlabel=empty
parted -s $freeloop unit B mkpart "${swappartlabel}" ext2 1048576 ` expr $swapblocks '*' 8388608 - 1 ` 

# Second partition - Blob
blobpartlabel="${brandshort}-BLOB"
[ "$blobblocks" -lt 32 ] && blobpartlabel=empty
if [ "$hcblocks" -lt 32 ] ; then
	parted -s $freeloop unit B mkpart "${blobpartlabel}" ext2 ` expr $swapblocks '*' 8388608 ` 100% 
else
	parted -s $freeloop unit B mkpart "${blobpartlabel}" ext2 ` expr $swapblocks '*' 8388608 `  ` expr '(' $swapblocks + $blobblocks ')' '*' 8388608 - 1 `
	# Third partition - encrypted container
	homepartlabel="${brandshort}-HOME"
	[ "$hcblocks" -lt 32 ] && homepartlabel=empty
	parted -s $freeloop unit B mkpart "${homepartlabel}" ext2 ` expr '(' $swapblocks + $blobblocks ')' '*' 8388608 ` 100% 
fi
sync 
sleep 10

parted -s -m $freeloop unit B print > /tmp/batchinstall/${tempdev}/looppart.txt
losetup -d $freeloop 
p1start=` grep '^1' /tmp/batchinstall/${tempdev}/looppart.txt | awk -F ':|B:' '{print $2}' `
p1size=`  grep '^1' /tmp/batchinstall/${tempdev}/looppart.txt | awk -F ':|B:' '{print $4}' `
p2start=` grep '^2' /tmp/batchinstall/${tempdev}/looppart.txt | awk -F ':|B:' '{print $2}' `
p2size=`  grep '^2' /tmp/batchinstall/${tempdev}/looppart.txt | awk -F ':|B:' '{print $4}' `
p3start=` grep '^3' /tmp/batchinstall/${tempdev}/looppart.txt | awk -F ':|B:' '{print $2}' `
p3size=`  grep '^3' /tmp/batchinstall/${tempdev}/looppart.txt | awk -F ':|B:' '{print $4}' `
if [ "$swapblocks" -gt 1  ] ; then
	nextloop=` losetup -f ` 
	losetup $nextloop -o $(( $p1start + $partend + 1 )) --sizelimit $p1size $device
	if=/dev/zero bs=1M count=8 of=$nextloop
	mkfs.ext2 -F -L LessLinuxSwap $nextloop
	sync
	losetup -d $nextloop
fi
if [ "$blobblocks" -gt 1  ] ; then
	nextloop=` losetup -f ` 
	losetup $nextloop -o $(( $p2start + $partend + 1 )) --sizelimit $p2size $device
	if=/dev/zero bs=1M count=8 of=$nextloop
	mkfs.ext2 -F -L LessLinuxBlob $nextloop
	sync
	losetup -d $nextloop
fi 
if [ "$hcblocks" -gt 31  ] ; then
	nextloop=` losetup -f ` 
	losetup $nextloop -o $(( $p3start + $partend + 1 )) --sizelimit $p3size $device
	if=/dev/zero bs=1M count=8 of=$nextloop
	mkfs.ext2 -F -L LessLinuxCrypt $nextloop
	sync 
	losetup -d $nextloop
fi 
sync 







