#!/bin/bash

. /etc/lesslinux/branding/branding.en.sh
. /etc/rc.subr/extractbootparams

device="/dev/$1"
lang="$2"
#homecontmax=0
#swapsize=2048
#blobsize=3072
tempdev=` uuidgen `
#lang=de
	
# Size of boot/isolinux directory in kilobytes
bootsize=` du -sk /lesslinux/cdrom/boot | awk '{print $1}' `
efidirsize=` du -sk /lesslinux/cdrom/boot/efi | awk '{print $1}' `
[ -z "$efidirsize" ] && efidirsize=0
bootsize=` expr $bootsize - $efidirsize ` 
# Size of boot partition in count of 8MB blocks - roughly add 50% for updates
bootblocks=` expr $bootsize / 5461 + 1 ` 
	
# Size of boot/efi.img in bytes
efisize=` ls -la /lesslinux/cdrom/boot/efi/efi.img | awk '{print $5}' ` 
[ -z "$efisize" ] && efisize=0 
# Size of EFI boot partition in count of 8MB blocks - roughly add 50% for updates
efiblocks=` expr $efisize / 5592404 ` 
[ "$efiblocks" -lt 1 ] && efiblocks=1
# Size of ISO image in kilobytes
isosize=` df -k | grep '/lesslinux/cdrom' | awk '{print $3}' `
# Size of ISO partition in count of 8MB blocks - roughly add 25% for updates
isoblocks=` expr $isosize / 6553 + 1 ` 
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
	
# Let the games begin...
#umount /lesslinux/cdrom
#lastct=` expr $isoblocks - 1 ` 
 	
#for i in ` seq 0 $lastct ` ; do
#	# go backwards
#	copyblock=` expr $lastct - $i ` 
#	tries=0
#	copyok=0
#	while [ $tries -lt 9 -a $copyok -lt 1 ] ; do
#		indev=` cat /var/run/lesslinux/install_source `
#		dd if=$indev of=/lesslinux/copyblock.bin bs=8388608 count=1 skip=$copyblock 2>/dev/null
#		dd if=/lesslinux/copyblock.bin of=$device bs=8388608 count=1 seek=` expr $deviceblocks - $i - 2 ` 2>/dev/null
#		sync
#		dd if=$device of=/lesslinux/checkblock.bin bs=8388608 count=1 skip=` expr $deviceblocks - $i - 2 ` 2>/dev/null
#		md5in=` sha1sum /lesslinux/copyblock.bin | awk '{print $1}' ` 
#		md5out=` sha1sum /lesslinux/checkblock.bin | awk '{print $1}' ` 
#		tries=` expr $tries + 1 ` 
#		if [ $md5in = $md5out ] ; then
#			copyok=1
#		else
#			echo "COPY FAILED on $i - trying again. Please consider replacing the target drive!"
#		fi
#	done
#done

echo '===> Creating partition table for'" $device"
	
# Recalculate the possible size of the partition for the encrypted home container
hcblocks=1
if [ "$homecontmax" -gt 0 ] ; then
	hcmaxblocks=` expr $homecontmax / 8 ` 
	hcminblocks=` expr $homecontmin / 8 ` 
	hcpossible=` expr $deviceblocks - $isoblocks - $isoblocks - $bootblocks - $efiblocks - $blobblocks - $swapblocks - 40 ` 
	if [ "$hcpossible" -gt $hcmaxblocks ] ; then
		hcblocks=$hcmaxblocks
	else
		hcblocks=$hcpossible
	fi
fi
	
# Create eight partitions: userdata (1), legacy boot (2), EFI boot (3), blob (4), encrypted home (5), encrypted swap (6), system reserved (for updates, 7), system ISO (8)
eighthpartstart=`   expr '(' $deviceblocks - $isoblocks - 1 ')' '*' 8388608 `
seventhpartstart=`  expr '(' $deviceblocks - $isoblocks - $isoblocks - 1 ')' '*' 8388608 `
sixthpartstart=`    expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - 1 ')' '*' 8388608 `
fifthpartstart=`    expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - 1 ')' '*' 8388608 `
fourthpartstart=`   expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - 1 ')' '*' 8388608 `
thirdpartstart=`    expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - $efiblocks - 1 ')' '*' 8388608 `
secpartstart=`      expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - $efiblocks - $bootblocks - 1 ')' '*' 8388608 `
	
# Now overwrite the start of the device
dd if=/dev/zero bs=1024 count=1024 of="$device"
# First create an DOS MBR with an active partition 
##parted -s $device unit B mklabel msdos
##parted -s $device unit B mkpart primary fat32 512 ` expr $thirdpartstart - 1 `
##parted -s $device unit B mkpart primary fat32 $thirdpartstart ` expr $fourthpartstart - 1 `
##parted -s $device unit B mkpart primary fat32 $fourthpartstart '100%'
##parted -s $device unit B set 2 boot on
##parted -s $device unit B set 2 esp on
##printf "print\nt\n3\n17\nwrite\nquit\n" | /static/sbin/fdisk $device
##printf "print\nt\n1\nee\nwrite\nquit\n" | /static/sbin/fdisk $device
sync
# Now backup this partition table
##dd if="$device" of=/tmp/legacy.mbr bs=512 count=1
##dd if=/dev/zero bs=1024 count=1 of="$device"
# Create the GPT partition table
parted -s $device unit B mklabel gpt
sync
mdev -s
	
# First partition - data
parted -s $device unit B mkpart "${brandshort}-DATA" fat32 8388608 ` expr $secpartstart - 1 `  
# Second partition - legacy boot
parted -s $device unit B mkpart "${brandshort}-BIOS" ext2 $secpartstart ` expr $thirdpartstart - 1 ` 
parted -s $device unit B set 2 legacy_boot on
# Third partition - EFI Boot
parted -s $device unit B mkpart "${brandshort}-UEFI" fat32 $thirdpartstart ` expr $fourthpartstart - 1 ` 
[ "$efisize" -gt 0 ] && parted -s $device unit B set 3 boot on
# Fourth partition - Blob
blobpartlabel="${brandshort}-BLOB"
[ "$blobblocks" -lt 32 ] && blobpartlabel=empty
parted -s $device unit B mkpart "${blobpartlabel}" ext2 $fourthpartstart ` expr $fifthpartstart - 1 ` 
# Fifth partition - encrypted container
homepartlabel="${brandshort}-HOME"
[ "$hcblocks" -lt 32 ] && homepartlabel=empty
parted -s $device unit B mkpart "${homepartlabel}" ext2 $fifthpartstart ` expr $sixthpartstart - 1 ` 
# Sixth partition - Swap
swappartlabel="${brandshort}-SWAP"
[ "$swapblocks" -lt 32 ] && swappartlabel=empty
parted -s $device unit B mkpart "${swappartlabel}" ext2 $sixthpartstart ` expr $seventhpartstart - 1 ` 
# Seventh partition - ISO image reserved
parted -s $device unit B mkpart "${brandshort}-SYS2" ext2 $seventhpartstart ` expr $eighthpartstart - 1 ` 
# Eight partition - ISO image
parted -s $device unit B mkpart "${brandshort}-SYS1" ext2 $eighthpartstart ` expr '(' $deviceblocks - 1 ')' '*' 8388608 - 1 `
# Write the MSDOS MBR and the GPT boot legacy block
# dd of="$device" if=/tmp/legacy.mbr bs=512 count=1
cat /etc/syslinux/gptmbr.bin > "$device"
# rm /tmp/legacy.mbr

dd if=/dev/urandom bs=1M count=1 of=/tmp/batchinstall/${tempdev}/swap.key 
mkdir -p /tmp/batchinstall/${tempdev}/boot
mkdir -p /tmp/batchinstall/${tempdev}/data
mkdir -p /tmp/batchinstall/${tempdev}/efiboot
mkdir -p /tmp/batchinstall/${tempdev}/blobpart
mkdir -p /tmp/batchinstall/${tempdev}/cdrom

sync 
sleep 2
echo "===> Create some filesystems for ${device}"
for part in ` seq 1 7 ` ; do
	dd if=/dev/zero bs=1M count=8 of=${device}${part} 
done

mkfs.ext2 -L LessLinuxBoot "${device}2"
[ "$blobblocks" -gt 1 ] && mkfs.btrfs -f -L LessLinuxBlob "${device}4"
[ "$hcblocks" -gt 1 ]   && mkfs.ext2 -L LessLinuxCrypt "${device}5"
[ "$swapblocks" -gt 1 ] && cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 --use-urandom -i 1000 -q "${device}6" /tmp/batchinstall/${tempdev}/swap.key 

mount -t ext4 -o rw "${device}2" /tmp/batchinstall/${tempdev}/boot || exit 1 
newuuid=` blkid -o udev "${device}2" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
cryptuuid=''
swapuuid=''
[ "$hcblocks" -gt 1 ]   && cryptuuid=` blkid -o udev "${device}5" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
[ "$swapblocks" -gt 1 ] && swapuuid=`  blkid -o udev "${device}6" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
echo "===> Install BIOS boot files for ${device}"
tar -C /lesslinux/cdrom -cf - boot/isolinux boot/grub boot/kernel | tar -C /tmp/batchinstall/${tempdev}/boot -xf -
touch /tmp/batchinstall/${tempdev}/boot/cmdline
# Copy GRUBs file to properly detect the boot partition
#idfile=` ls /tmp/batchinstall/${tempdev}/boot/grub/????????.cd `
#idtarg=` echo $idfile | sed 's/\.cd/.pt/g' ` 
#mv $idfile $idtarg
#[ -f /etc/lesslinux/branding/postisoconvert.sh ] && /etc/lesslinux/branding/postisoconvert.sh
#if [ -d /etc/lesslinux/branding/postisoconvert.d ] ; then
#	find /etc/lesslinux/branding/postisoconvert.d -type f | sort | while read scrp ; do
#		/static/bin/ash $scrp
#	done
# fi
# Copy EFI boot image
echo "===> Install EFI boot image for ${device}"
if [ -f /lesslinux/cdrom/boot/efi/efi.img ] ; then
	dd if=/lesslinux/cdrom/boot/efi/efi.img of="${device}3" || exit 1
	mount -t vfat -o rw "${device}3" /tmp/batchinstall/${tempdev}/efiboot || exit 1 
	# Modify EFI boot files
	find /tmp/batchinstall/${tempdev}/efiboot/loader -type f -name '*.usb' | while read cfgfile ; do 
		outfile=` echo ${cfgfile} | sed 's/\.usb$/.conf/g' `
		cp -v ${cfgfile} ${outfile} 
	done
	find /tmp/batchinstall/${tempdev}/efiboot/loader -type f -name '*.conf' | while read cfgfile ; do 
		[ -f "${cfgfile}.${lang}" ] && cp "${cfgfile}.${lang}" "${cfgfile}"
		sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
		[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
		[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
		[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
	done
	mkdir -p /tmp/batchinstall/${tempdev}/efiboot/boot/isolinux
	extlinux --install /tmp/batchinstall/${tempdev}/efiboot/boot/isolinux
	sync
	umount /tmp/batchinstall/${tempdev}/efiboot
fi
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
[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf
[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf
[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    /tmp/batchinstall/${tempdev}/boot/boot/isolinux/extlinux.conf

echo -n "${newuuid}" > /tmp/batchinstall/${tempdev}/boot/boot.uuid
echo -n "${cryptuuid}" > /tmp/batchinstall/${tempdev}/boot/crypt.uuid
echo -n "${swapuuid}" > /tmp/batchinstall/${tempdev}/boot/swap.uuid
extlinux --install /tmp/batchinstall/${tempdev}/boot/boot/isolinux
sync 
umount /tmp/batchinstall/${tempdev}/boot
umount /tmp/batchinstall/${tempdev}/efiboot

if [ "$secpartstart" -gt 4294967295 ] ; then
	mkntfs -F -Q -L USBDATA "${device}1"
	mount -t ntfs-3g -o rw "${device}1" /tmp/batchinstall/${tempdev}/data || exit 1
else
	mkfs.vfat -n USBDATA "${device}1"
	mount -t vfat -o rw,iocharset=utf8 "${device}1" /tmp/batchinstall/${tempdev}/data || exit 1 
fi

echo "===> Install image on target device ${device}8"
dd if=` cat /var/run/lesslinux/install_source ` of=${device}8 || exit 1 
sync

echo "===> Install kickstart.iso, manuals and stuff on ${device}1"
# Important: Create kickstart.iso
if [ -f /lesslinux/cdrom/boot/kickstart.xd3 ]  ; then
	for f in ` cat /lesslinux/cdrom/lesslinux/boot.sha | awk '{print $2}' `; do
		cat /lesslinux/cdrom/boot/kernel/${f} >> /tmp/batchinstall/${tempdev}/data/kickstart.raw
	done
	cat /lesslinux/cdrom/boot/efi/efi.img >> /tmp/batchinstall/${tempdev}/data/kickstart.raw
	xdelta3 -d -s /tmp/batchinstall/${tempdev}/data/kickstart.raw /lesslinux/cdrom/boot/kickstart.xd3 \
		/tmp/batchinstall/${tempdev}/data/kickstart.iso
	rm /tmp/batchinstall/${tempdev}/data/kickstart.raw
fi
tar -C /lesslinux/cdrom -cf - Manual autorun.usb GPL.txt license | tar -C  /tmp/batchinstall/${tempdev}/data -xf -
mv /tmp/batchinstall/${tempdev}/data/autorun.usb /tmp/batchinstall/${tempdev}/data/autorun.inf
if [ -f /etc/lesslinux/branding/extrafiles.txt ] ; then
	for fname in ` cat /etc/lesslinux/branding/extrafiles.txt `] ; do
		tar -C /lesslinux/cdrom -cf - $fname | tar -C  /tmp/batchinstall/${tempdev}/data -xf - 
	done
fi
sync
umount /tmp/batchinstall/${tempdev}/data
mount -o ro "${device}8" /tmp/batchinstall/${tempdev}/cdrom 
if ( cd /tmp/batchinstall/${tempdev}/cdrom/lesslinux ; sha1sum -c squash.sha ) ; then
	echo "===> Check of system on ${device}8 succesful"
	umount  /tmp/batchinstall/${tempdev}/cdrom
else
	echo "===> Check of system on ${device}8 FAILED"
	umount  /tmp/batchinstall/${tempdev}/cdrom
	exit 1
fi
mount -o ro "${device}8" /tmp/batchinstall/${tempdev}/cdrom 
mount -o ro "${device}2" /tmp/batchinstall/${tempdev}/boot 
if ( cd /tmp/batchinstall/${tempdev}/boot/boot/kernel/ ; sha1sum -c /tmp/batchinstall/${tempdev}/cdrom/lesslinux/boot.sha ) ; then
	echo "===> Check of boot files on ${device}2 succesful"
	umount  /tmp/batchinstall/${tempdev}/cdrom
	umount  /tmp/batchinstall/${tempdev}/boot 
else
	echo "===> Check of boot files on ${device}2 FAILED"
	umount  /tmp/batchinstall/${tempdev}/cdrom
	umount  /tmp/batchinstall/${tempdev}/boot 
	exit 1
fi
mount -o ro "${device}3" /tmp/batchinstall/${tempdev}/efiboot 
if ( cd /tmp/batchinstall/${tempdev}/efiboot ; sha1sum -c efi.sha ) ; then
	echo "===> Check of EFI boot files on ${device}3 succesful"
	umount  /tmp/batchinstall/${tempdev}/efiboot
else
	echo "===> Check of EFI boot files on ${device}3 FAILED"
	umount  /tmp/batchinstall/${tempdev}/efiboot
	exit 1
fi

for d in blobpart boot cdrom data efiboot ; do
	rmdir /tmp/batchinstall/${tempdev}/${d}
done
rm /tmp/batchinstall/${tempdev}/swap.key 
rmdir /tmp/batchinstall/${tempdev}

exit 0
