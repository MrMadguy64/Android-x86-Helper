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
	
	#Set these variables here, othervise clean_branch wouldn't work
	if [ "$out_directory" != "no" ]
	then
		mkdir -p $out_directory
		real_out="$(realpath $out_directory)"
		real_suffix="android_$branch_name"
		full_out="$real_out/$real_suffix"
		if [ "$use_common_base" = "yes" ]
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
			#Backup sandbox_linux.go
			check_backup build/soong/ui/build/sandbox_linux.go
			#Backup config.go
			check_backup build/soong/ui/build/paths/config.go
			#Backup kernel.mk
			check_backup device/generic/common/build/tasks/kernel.mk
			#Choose make style
			case $make_style in
				"old")
					#Use buildspec.mk - isn't supported in newer Android versions
					echo TARGET_PRODUCT := $arch_name > buildspec.mk
					echo TARGET_BUILD_VARIANT := $target >> buildspec.mk
					echo TARGET_BUILD_TYPE := $build >> buildspec.mk
					echo TARGET_KERNEL_CONFIG := android-${arch_vers}_${kernel} >> buildspec.mk
					#Disable sandboxing in case of problems with nsjail
					if [ "$disable_sandbox" = "yes" ]
					then
						sed -i 's#if !c.Sandbox.Enabled {#return false\n\tif true {#g' build/soong/ui/build/sandbox_linux.go
					fi
					#Kernel: depmod patch for Android 10 kernel
					sed -i 's#"dd":       Allowed,#"dd":       Allowed,\n\t"depmod"    :Allowed,#g' build/soong/ui/build/paths/config.go
					#Kernel: bison/ld patch in case of using OUT_DIR or OUT_DIR_COMMON_BASE					
					sed -i 's#ln -sf ../../../../../../prebuilts#ln -sf $(abspath ./prebuilts)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(LLVM_PREBUILTS_PATH)/llvm-ar#ln -sf $(abspath ./$(LLVM_PREBUILTS_PATH)/llvm-ar)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(LLVM_PREBUILTS_PATH)/ld.lld#ln -sf $(abspath ./$(LLVM_PREBUILTS_PATH)/ld.lld)#g' device/generic/common/build/tasks/kernel.mk
					sed -i 's#ln -sf ../../$(dir $(TARGET_TOOLS_PREFIX))x86_64-linux-androidkernel-*#ln -sf $(abspath ./$(dir $(TARGET_TOOLS_PREFIX))x86_64-linux-androidkernel-*)#g' device/generic/common/build/tasks/kernel.mk
					#Old style make
					make -j$cpus iso_img
				;;
				"new")
					#Remove buildspec.mk, if exists
					rm -f buildspec.mk
					#Use envsetup.sh, lunch and m - recommended
					. build/envsetup.sh
					export TARGET_KERNEL_CONFIG=android-${arch_vers}_${kernel}
					#Disable sandboxing in case of problems with nsjail
					if [ "$disable_sandbox" = "yes" ]
					then
						sed -i 's#if !c.Sandbox.Enabled {#return false\n\tif true {#g' build/soong/ui/build/sandbox_linux.go
					fi
					#Configure build environment
					lunch $arch_name-$target
					#Kernel: depmod patch for Android 10 kernel
					sed -i 's#"dd":       Allowed,#"dd":       Allowed,\n\t"depmod"    :Allowed,#g' build/soong/ui/build/paths/config.go
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
			clean_out $clean_arch $real_out $real_suffix
		fi
	done

	#Remove out dir, if you don't have enough space to keep it (~100G per target)	
	clean_out $clean_branch $real_out $real_suffix
	
	#Leave branch source directory
	cd ..
done
