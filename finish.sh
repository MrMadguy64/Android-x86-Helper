#!/bin/bash

. ./config.sh
. ./tools.sh

#Restore all common backups
restore_backup /etc/java-8-openjdk/security/java.security

#Restore all branch-specific backups
for branch in $branches
do
	temp=${branch%=*}
	branch_name=${temp%=*}
	branch_manifest=${temp#*=}
	branch_vers=${branch##*=}
	
	folder=android_$branch_name
	
	if [ -d $folder ]
	then
		cd $folder
		
		restore_backup .repo/manifests/$branch_manifest.xml
		restore_backup device/generic/common/device.mk
		restore_backup vendor/opengapps/build/opengapps-packages.mk
		restore_backup build/soong/ui/build/sandbox_linux.go
		restore_backup check_backup external/drm_hwcomposer/drmhwctwo.cpp
		restore_backup device/generic/common/build/tasks/kernel.mk
		
		cd ..
	fi
done
	