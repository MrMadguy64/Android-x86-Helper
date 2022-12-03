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
	
	#Backup manifest
	check_backup .repo/manifests/$branch_manifest.xml
	
	#Add OpenGApps to manifest
	if [ $opengapps != "no" ]
	then
		cp ../opengapps.xml .repo/manifests/
		sed -i 's#</manifest>#\n  <include name="opengapps.xml" />\n\n#g' .repo/manifests/$branch_manifest.xml
		echo '</manifest>' >> .repo/manifests/$branch_manifest.xml
	else
		rm -f .repo/manifests/opengapps.xml
	fi
	
	#Sync main repo
	while true
	do
		python3 repo sync --no-tags --no-clone-bundle
		
		#Ask, if sync completed successfully
		if [ $override_sync = "yes" ]
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
	
	#Warning: removing opengapps - is only way to disable it. You would need to download it again!
	if [ $opengapps != "no" ]
	then		
		#Install OpenGApps to device.mk
		if [ $override_webview = "yes" ]
		then
			sed -i "1s/^/GAPPS_FORCE_WEBVIEW_OVERRIDES := true\n/" device/generic/common/device.mk				
		fi 
		if [ $override_browser = "yes" ]
		then
			sed -i "1s/^/GAPPS_FORCE_BROWSER_OVERRIDES := true\n/" device/generic/common/device.mk				
		fi 
		if [ $packages != "no" ]
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
			python3 repo forall -c git lfs pull
			
			#Ask, if download completed successfully
			if [ $override_sync = "yes" ]
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
		cd vendor
		rm -rf opengapps
		cd ..
	fi
		
	cd ..
done
