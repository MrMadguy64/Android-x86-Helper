#!/bin/bash

. ./config.sh
. ./tools.sh

#It's separate script, so set this varaibles again
case $dest_type in
	"directory")
		dest_dir=$export_dir
	;;
	"network")
		dest_dir="/mnt/"
	;;
esac

#Branch building
for branch in $branches
do	
	temp=${branch%=*}
	branch_name=${temp%=*}
	branch_manifest=${temp#*=}
	branch_vers=${branch##*=}
	
	#Enter branch source directory
	cd android_$branch_name	
	
	#Arch building
	for arch in $arches
	do
		arch_name=${arch%=*}
		arch_vers=${arch#*=}
		
		dest_name="arch/x86/configs/android-${arch_vers}_${kernel})"
		
		/usr/bin/make -C kernel menuconfig KCONFIG_CONFIG=$dest_name
	done
	
	#Leave branch source directory
	cd ..
done
