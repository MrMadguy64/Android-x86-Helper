#!/bin/bash

. ./config.sh

#I like to use htop to monitor system resources
mate-terminal -e htop &

#Make swap file
if [ $swap = "yes" ]
then
	#Don't remake, if it already exists
	if ! [ -f swapfile ]
	then
		fallocate -l $(( $swap_size+$ramdisk_size ))G swapfile
		chmod 600 swapfile
		mkswap swapfile
	fi
	
	swapon swapfile
	
	#Expand tmp file system
	if [ $ramdisk_size -ge 0 ] 
	then
		sed -i "s/nosuid,nodev/size=${ramdisk_size}g/g" /etc/fstab
		mount -o remount /tmp
	fi
fi

#Mount SMB directory if necessary
case $dest_type in
	"directory")
		dest_dir=$export_dir
		mkdir -p dest_dir
	;;
	"network")
		dest_dir="/mnt/"
		mount -t cifs $src_dir $dest_dir -o rw,uid=1000,gid=1000,username=$src_user,password=$src_pwd
	;;
esac

#Install required tools
apt-get update

#Downloading from external repos can fail due to expired certificates
apt-get install -y --only-upgrade ca-certificates
update-ca-certificates

#AOSP and Android-x86 tools merged
apt-get install -y \
git-core gnupg flex bison build-essential zip curl \
zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
libncurses5 lib32ncurses5-dev x11proto-core-dev libx11-dev \
lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
git git-lfs gcc make libxml2-utils flex m4 \
openjdk-8-jdk lib32stdc++6 libelf-dev mtools \
libssl-dev python-enum34 python-mako syslinux-utils
