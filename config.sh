#!/bin/bash

#***Build settings***

#Manifest URL
source="git://git.osdn.net/gitroot/android-x86/manifest"
#Space separated list of items with following format "BRANCH=MANIFEST=VERSION"
branches="pie-x86=android-x86-9.0-r2=9.0 q-x86=default=10.0 r-x86=default=11.0"
#Space separated list of items with following format "TARGET_PRODUCT=ARCH"
arches="android_x86=x86 android_x86_64=x86_64"
#Value for TARGET_BUILD_VARIANT
target="user"
#Value for TARGET_BUILD_TYPE
build="release"
#Value for TARGET_KERNEL_CONFIG
kernel="defconfig"
#Number of CPUs for Make
cpus="4"
#OpenGApps variant: "no" to disable, otherwise - value for GAPPS_VARIANT
opengapps="pico"
#OpenGApps packages: "no" to disable, otherwise - value for GAPPS_PRODUCT_PACKAGES
packages="Chrome WebViewGoogle PrebuiltGmail Velvet"
#OpenGApps overrides: "no" to disable, otherwise - values for GAPPS_PACKAGE_OVERRIDES 
override_packages=$packages
#OpenGApps browser: "no" to disable, "yes" to set GAPPS_FORCE_BROWSER_OVERRIDES := true
override_browser="yes"
#OpenGApps WebView: "no" to disable, "yes" to set GAPPS_FORCE_WEBVIEW_OVERRIDES := true
override_webview="yes"
#Make call style: "old" for using buildspec.mk, "new" for using lunch
make_style="new"
#Override OUT_DIR variable: "no" to disable, anything else to enable (relative paths are allowed)
out_directory="../../Android"
#Use common base: "no" for setting OUT_DIR, "yes" for setting OUT_DIR_COMMON_BASE
use_common_base="yes"
#Disable sandbox: "no" to use default sandbox settings, "yes" in case of problems with nsjail
disable_sandbox="yes"

#***System settings***

#[Unused] Base directory, script was executed from
base_dir=$PWD
#Destination to export to: "directory" to use "export_dir", "network" to use "src_dir" instead
dest_type="network"
#Network SMB directory: "//address/dir"
src_dir="//192.168.0.1/linux"
#User name for SMB directory
src_user="User"
#Password for SMB directory
src_pwd="12345"
#Local directory to export to
export_dir="../export"
#Enable swap: "no" to disable, "yes" for live session
swap="yes"
#Total swap size in gigabytes (16Gb physical memory is recommened for Android 11, succeeded with 14Gb) 
swap_size=8
#[Unused, should be 0] Amount of swap in gigabytes to be used to expand tmp file system
ramdisk_size=0

#***Misc settings***

#Override resync query behavior: "no" - ask, "yes" - override
override_sync="yes"
#[Untested] Remove out dir after every branch: "ask" - show query, "no" - keep it, "yes" - remove
clean_branch="no"
#[Untested] Remove out dir after every arch: "ask" - show query, "no" - keep it, "yes" - remove
clean_arch="no"
