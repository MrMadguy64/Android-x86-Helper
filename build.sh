#!/bin/bash

. ./config.sh

#I like to use htop to monitor system resources
mate-terminal -e htop &

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
	
	#Set these variables here, othervise clean_branch wouldn't work
	if [ $out_directory != "no" ]
	then
		mkdir -p $out_directory
		real_out="$(realpath $out_directory)"
		real_suffix="android_$branch_name"
		full_out="$real_out/$real_suffix"
		if [ $use_common_base = "yes" ]
		then
			export OUT_DIR_COMMON_BASE=$real_out
		else
			export OUT_DIR=$full_out
		fi
	else
		real_out="$(realpath .)"
		real_suffix="out"
		full_out="$real_out/$real_suffix"
	fi
	
	#Arch building
	for arch in $arches
	do
		arch_name=${arch%=*}
		arch_vers=${arch#*=}
		
		dest_file=android-$arch_vers-$branch_vers.iso
		dest_name=$dest_dir$dest_file
		
		if [ ! -f $dest_name ]
		then        		
			#Choose make style
			case $make_style in
				"old")
					#Use buildspec.mk - isn't supported in newer Android versions
					echo TARGET_PRODUCT := $arch_name > buildspec.mk
					echo TARGET_BUILD_VARIANT := $target >> buildspec.mk
					echo TARGET_BUILD_TYPE := $build >> buildspec.mk
					echo TARGET_KERNEL_CONFIG := android-${arch_vers}_${kernel} >> buildspec.mk
					#Disable sandboxing in case of problems with nsjail
					case $disable_sandbox in
						"yes")
							sed -i 's#if !c.Sandbox.Enabled {#return false\n\tif true {#g' build/soong/ui/build/sandbox_linux.go
						;;
						"no")
							sed -i 's#return false\n\tif true {#if !c.Sandbox.Enabled {#g' build/soong/ui/build/sandbox_linux.go
						;;
					esac
					#Kernel: depmod patch for Android 10 kernel
					sed -i 's#"dd":       Allowed,#"dd":Allowed,\n\t"depmod":Allowed,#g' build/soong/ui/build/paths/config.go
					#Kernel: bison/ld patch in case of using OUT_DIR or OUT_DIR_COMMON_BASE					
					sed -i 's#ln -sf ../../../../../../prebuilts#ln -sf $(abspath ./prebuilts)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(LLVM_PREBUILTS_PATH)/llvm-ar#ln -sf $(abspath ./$(LLVM_PREBUILTS_PATH)/llvm-ar)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(LLVM_PREBUILTS_PATH)/ld.lld#ln -sf $(abspath ./$(LLVM_PREBUILTS_PATH)/ld.lld)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(dir $(TARGET_TOOLS_PREFIX))x86_64-linux-androidkernel-*#ln -sf $(abspath ./$(dir $(TARGET_TOOLS_PREFIX))x86_64-linux-androidkernel-*)#g' device/generic/common/build/tasks/kernel.mk
					#Old style make
					make -j$cpus iso_img
				;;
				"new")
					#Use envsetup.sh, lunch and m - recommended
					. build/envsetup.sh
					export TARGET_KERNEL_CONFIG=android-${arch_vers}_${kernel}
					#Disable sandboxing in case of problems with nsjail
					case $disable_sandbox in
						"yes")
							sed -i 's#if !c.Sandbox.Enabled {#return false\n\tif true {#g' build/soong/ui/build/sandbox_linux.go
						;;
						"no")
							sed -i 's#return false\n\tif true {#if !c.Sandbox.Enabled {#g' build/soong/ui/build/sandbox_linux.go
						;;
					esac
					lunch $arch_name-$target
					#Kernel: depmod patch for Android 10 kernel
					sed -i 's#"dd":       Allowed,#"dd":Allowed,\n\t"depmod":Allowed,#g' build/soong/ui/build/paths/config.go
					#Kernel: bison/ld patch in case of using OUT_DIR or OUT_DIR_COMMON_BASE	
					sed -i 's#ln -sf ../../../../../../prebuilts#ln -sf $(abspath ./prebuilts)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(LLVM_PREBUILTS_PATH)/llvm-ar#ln -sf $(abspath ./$(LLVM_PREBUILTS_PATH)/llvm-ar)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(LLVM_PREBUILTS_PATH)/ld.lld#ln -sf $(abspath ./$(LLVM_PREBUILTS_PATH)/ld.lld)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(dir $(TARGET_TOOLS_PREFIX))x86_64-linux-androidkernel-*#ln -sf $(abspath ./$(dir $(TARGET_TOOLS_PREFIX))x86_64-linux-androidkernel-*)#g' device/generic/common/build/tasks/kernel.mk
					#New style make
					m -j$cpus iso_img
				;;
			esac
			
			#Export output file
			cp -f $full_out/target/product/$arch_vers/$arch_name.iso $dest_name
			
			#Remove out dir, if you don't have enough space to keep it (~100G per target)
			case $clean_arch in
				"yes")
					#Always remove (unrecommended, if you aren't 100% sure, that build will succeed)
					temp=$PWD
					cd $real_out
					rm -rf $real_suffix
					cd $temp
				;;
				"ask")
					#Ask (recommended)
					read -p "Do you want to clean out directory? [y/n]" yn
					case $yn in
						"y")
							temp=$PWD
							cd $real_out
							rm -rf $real_suffix
							cd $temp
						;;
						"n")
							exit
						;;
					esac
				;;
			esac
		fi
	done

	#Remove out dir, if you don't have enough space to keep it (~100G per target)	
	case $clean_branch in
		"yes")
			#Always remove (unrecommended, if you aren't 100% sure, that build will succeed)
			temp=$PWD
			cd $real_out
			rm -rf $real_suffix
			cd $temp
		;;
		"ask")
			#Ask (recommended)
			read -p "Do you want to clean out directory? [y/n]" yn
			case $yn in
				"y")
					temp=$PWD
					cd $real_out
					rm -rf $real_suffix
					cd $temp
				;;
				"n")
					exit
				;;
			esac
		;;
	esac
	
	#Leave branch source directory
	cd ..
done
