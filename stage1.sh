#!/bin/bash

CREDITS="the_grugq"
AUTHOR="Kn0bl3"
CONTACT="kn0bl3@riseup.net (XMPP/EMAIL)"
VERSION="v0.10"


function GREETING {

	echo "Kn0bl3's $VERSION RPI 2/3 Tor router build scripts. based on and credits to $CREDITS's work."
}

function GET_DEV_FILE {
	echo "Insert the microsd card that will be used as storage for the Tor router and enter the full filesystem path to the device file of the SD card (EX: /dev/sdz): "
	read DEVFILE
	if [[ $(file $DEVFILE | grep "No such file or directory") ]]; then
		echo "ERROR: $DEVIFILE does not exist!"
		GET_DEV_FILE
	elif [[ $(whoami) != "root" ]]; then
		echo "ERROR: Script must be run as root!"
		GET_DEV_FILE
	fi
	return $DEVFILE
}

function GET_OS_IMG {
	if [[ $(file "ArchLinuxARM-rpi-2-latest.tar.gz" | grep -v -i "gzip") ]]; then
		wget "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz" --show-progress
	fi
	OS_iMG="ArchLinuxARM-rpi-2-latest.tar.gz"
}

function PREP_SD_CARD {
	fdisk $DEVFILE << __EXIT__
o
p
n
p
1

+100M
t
c
n
p



2
p
w
q
__EXIT__
}

function FLASH_IMG_FILES {
	mkdir boot root
	mkfs.vfat "$DEVFILE"1
	mount "$DEVFILE"1 boot/
	mkfs.ext4 "$DEVFILE"2
	mount "$DEVFILE"2 root/
	bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C root
	sync
	mv root/boot/* boot
	umount root boot
}


GREETING

GET_DEV_FILE

GET_OS_IMG

PREP_SD_CARD

FLASH_IMG_FILES

echo "STAGE 1 COMPLETE! execute stage2.sh on the freshly installed RPI via ssh or local console" 
