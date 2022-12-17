#!/bin/bash

. ./config.sh
. ./tools.sh

for branch in $branches
do
	temp=${branch%=*}
	branch_name=${temp%=*}
	branch_manifest=${temp#*=}
	branch_vers=${branch##*=}
	
	folder=android_$branch_name
	
	if ! [ -d $folder ]
	then
		#Make source folder for branch
		mkdir -p $folder
		cd $folder
		
		#Download repo (OS built-in version doesn't work)
		curl https://storage.googleapis.com/git-repo-downloads/repo-1 > repo
		chmod a+x repo
		
		#Init repo
		python3 repo init -u $source -m $branch_manifest.xml -b $branch_name
	else
		cd $folder
	fi
	
	#Backup manifest - can't restore this backup, cuz it's required for resync
	check_backup .repo/manifests/$branch_manifest.xml
	
	#Add OpenGApps to manifest
	if [ "$opengapps" != "no" ]
	then
		cp ../opengapps.xml .repo/manifests/
		sed -i 's#</manifest>#\n  <include name="opengapps.xml" />\n\n#g' .repo/manifests/$branch_manifest.xml
		echo '</manifest>' >> .repo/manifests/$branch_manifest.xml
	else
		rm -f .repo/manifests/opengapps.xml
	fi
	
	#Path for Android 10 to fix lack of gcc 4.6
	sed -i 's#x86_64-linux-glibc2.11-4.6" revision="master"#x86_64-linux-glibc2.11-4.6" revision="eb5c9f0ae36bf964f6855bde54e1b387e2c26bb6"#g' .repo/manifests/$branch_manifest.xml
	
	#Restore all backups before resyncing - these files can be updated during resync
	restore_backup device/generic/common/device.mk
	restore_backup vendor/opengapps/build/opengapps-packages.mk
	restore_backup build/soong/ui/build/sandbox_linux.go
	restore_backup check_backup external/drm_hwcomposer/drmhwctwo.cpp
	restore_backup device/generic/common/build/tasks/kernel.mk
	
	#Sync main repo
	while true
	do
		python3 repo sync --no-tags --no-clone-bundle
		
		#Ask, if sync completed successfully
		if [ "$override_sync" = "yes" ]
		then
			break
		fi
		
		#Type "y" to continue, "n" to stop script, anything else to resync
		read -p "Has operation completed successfully? [y/n]" yn
		case $yn in
			"y")
				break
			;;
			"n")
				exit
			;;
		esac
	done

	#Backup device.mk
	check_backup device/generic/common/device.mk
	
	#Configure OpenGApps, if it's enabled
	if [ "$opengapps" != "no" ]
	then		
		#Install OpenGApps to device.mk
		if [ "$override_webview" = "yes" ]
		then
			sed -i "1s/^/GAPPS_FORCE_WEBVIEW_OVERRIDES := true\n/" device/generic/common/device.mk				
		fi 
		if [ "$override_browser" = "yes" ]
		then
			sed -i "1s/^/GAPPS_FORCE_BROWSER_OVERRIDES := true\n/" device/generic/common/device.mk				
		fi 
		if [ "$override_packages" != "no" ]
		then
			sed -i "1s/^/GAPPS_PACKAGE_OVERRIDES += $override_packages\n/" device/generic/common/device.mk
		fi
		if [ "$packages" != "no" ]
		then
			sed -i "1s/^/GAPPS_PRODUCT_PACKAGES += $packages\n/" device/generic/common/device.mk
		fi
		sed -i "1s/^/GAPPS_VARIANT := $opengapps\n/" device/generic/common/device.mk
		
		#Following patch is no longer needed, as device.mk already have it - it would cause duplicate targets
		#echo >> device/generic/common/device.mk
		#echo '$(call inherit-product, vendor/opengapps/build/opengapps-packages.mk)' >> device/generic/common/device.mk
		#echo >> device/generic/common/device.mk
		
		#Patches to fix OpenGApps build problems
		echo '$(call add-clean-step, rm -rf $(PRODUCT_OUT)/system/priv-app/*)' > vendor/opengapps/build/CleanSpec.mk
		echo '$(call add-clean-step, rm -rf $(PRODUCT_OUT)/system/app/*)' >> vendor/opengapps/build/CleanSpec.mk
		echo 'include $(call all-named-subdir-makefiles,$(GAPPS_PRODUCT_PACKAGES))' > vendor/opengapps/build/modules/Android.mk
		
		#Backup opengapps-packages.mk
		check_backup vendor/opengapps/build/opengapps-packages.mk
		
		#Disable some apps. Isn't needed for pico.
		sed -i '/MarkupGoogle/d' vendor/opengapps/build/opengapps-packages.mk
		sed -i '/GoogleCamera/d' vendor/opengapps/build/opengapps-packages.mk
		
		#Download OpenGApps files via lfs
		while true
		do
			for dir in all x86 x86_64
			do
				temp=$PWD
				cd vendor/opengapps/sources/$dir
				git lfs pull
				cd $temp
			done
			
			#Ask, if download completed successfully
			if [ "$override_sync" = "yes" ]
			then
				break
			fi
			
			#Type "y" to continue, "n" to stop script, anything else to resync
			read -p "Has operation completed successfully? [y/n]" yn
			case $yn in
				"y")
					break
				;;
				"n")
					exit
				;;
			esac
		done
	else
		#Warning: OpenGApps files are large! Downloading them again will take time!
		rm -rf vendor
	fi
		
	cd ..
done

