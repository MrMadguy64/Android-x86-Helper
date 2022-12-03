#!/bin/bash

#Backup file, if backup doesn't exist, otherwise - restore backup
#$1 - file name (required)
check_backup() {
	#File name is required
	if [ $# -ne 1 ]
	then
		return
	fi
	#Cache backup file name
	local backup_file="$1.bak"
	#Perform operation, depending on existance of backup file
	if [ -f $backup_file ]
	then
		cp -f $backup_file $1
	else
		cp -f $1 $backup_file
	fi
}

#Clean out directory
#$1 - override mode: "ask", "no", "yes" (required)
#$2 - base output directory (required)
#$3 - output directory name (required)
clean_out() {
	#All parameters required
	if [ $# -ne 3 ]
	then
		return
	fi
	#"yes" to always clean, "ask" to ask, otherwise ("no" for example) - don't clean
	case $1 in
		"yes")
			#Always remove (unrecommended, if you aren't 100% sure, that build will succeed)
			local temp=$PWD
			cd $2
			rm -rf $3
			cd $temp
		;;
		"ask")
			#Ask (recommended)
			read -p "Do you want to clean out directory? [y/n]" yn
			case $yn in
				"y")
					temp=$PWD
					cd $2
					rm -rf $3
					cd $temp
				;;
				"n")
					exit
				;;
			esac
		;;
	esac
}
