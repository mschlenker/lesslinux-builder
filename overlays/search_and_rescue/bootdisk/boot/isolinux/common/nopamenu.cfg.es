MENU INCLUDE /boot/isolinux/common/colors.cfg
MENU INCLUDE /boot/isolinux/common/title.cfg
TIMEOUT 100

MENU INCLUDE /boot/isolinux/es/nopa/default.cfg
MENU BEGIN sfenpaem
	MENU TITLE Safe startup
	LABEL back
		MENU LABEL Go back
		MENU EXIT
	MENU INCLUDE /boot/isolinux/es/nopa/safemode.cfg
MENU END
LABEL memtest
MENU LABEL Test your memory
KERNEL /boot/isolinux/memtest.bzi
# APPEND initrd=/boot/isolinux/memtest.img
MENU INCLUDE /boot/isolinux/es/boot0x80.cfg
# MENU INCLUDE /boot/isolinux/es/usbonly.cfg
MENU INCLUDE /boot/isolinux/common/nopalang.cfg

