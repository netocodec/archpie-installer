#!/bin/bash

clear

application_title="ArchPie Linux V0.1-Alpha"
rasp_pi_version=""
quit_mode=0

declare -a disks
disk_index=-1

echo $application_title
echo ""

clean_up(){
	quit_mode=1
	clear
}

check_dependencies(){
	echo "Checking required dependencies..."
	echo ""
	existdep="`which dialog`"

	if [ ${#existdep} -eq 0 ];then
		echo "Missing some dependencies!"
		echo "Installing depedencies for you!"
		echo ""
		sudo apt -y install dialog
	fi
}

download_image(){
	dialog --title "$application_title" --gauge "Download Image..." 0 0 10 &
	wget --no-verbose "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi$rasp_pi_version-latest.tar.gz" -O arch_image.tar.gz
}


confirm_disk_formation(){
	dialog --title "$application_title" --yesno "Are you shure you want to format ${disks[disk_index]}?" 0 0
	if [ $? = 0 ];
    then
		echo "YES! $disk_index"
	fi
}

get_disks(){
	# Get all the disks and filter the uselless partitions.
	disk_list=$(sudo fdisk -l | grep "Disk /" | grep -v "/loop" | grep -v "/mapper/" | grep -v "/ram" | sort)

	# Syntax to replace all occurrences of ": " with " "
	disk_separation=(${disk_list//": "/ })
	index=0
	for val in "${disk_separation[@]}";
	do
		if [[ "$val" == *"/dev/"* ]];then
			disks+=("$val")
			index=`expr $index + 1`
		fi
	done
}

choose_disks(){
	dialog --title "$TITLE" --infobox 'Detecting Disks...' 10 50 &
	get_disks

	if [ ${#disks[@]} -gt 0 ];then
		index=0
		declare -a disk_options
		for val in "${disks[@]}";
		do
			if [ $index -eq 0 ];then
				disk_options+=($index "$val" on)
			else
				disk_options+=($index "$val" off)
			fi
			index=`expr $index + 1`
		done

		choosen_disk=$( dialog --stdout --title "$application_title" --radiolist "Select the disk you want to deploy the OS." \
			0 0 0 \
			${disk_options[@]}) 

		if [ "$choosen_disk" != "" ]; then
			# Confirm the disk partition and format it!
			disk_index=$choosen_disk
			confirm_disk_formation
		else
			clean_up
		fi
	else
		dialog --title "$application_title" --msgbox "Cannot get any disk! Please check if you have any SD card plugged-in!" 0 0
		clean_up
	fi
}

deploy_image(){
	dialog --title "$application_title" --gauge "Unpack Image..." 0 0 40 &

	# Replace the bsdtar dependency with the "tar" dependency.
	# Using SU command to untar the image into the root partition of the SD card
	sudo su -c "tar -xpsf arch_image.tar.gz -C root"

	dialog --title "$application_title" --gauge "Syncronize Image..." 0 0 60 &
	sync
}

format_partitions(){
echo "Format Partitions"
}

select_rasp_pi_version(){
	version=$( dialog --stdout --title "$application_title" --radiolist "Select the raspberry pi version." \
		0 0 0 \
		RPI1 'Raspberry PI 1/Zero' on \
		RPI2 'Raspbperry PI 2' off \
		RPI3 'Raspberry PI 3' off \
		RPI4 'Raspberry PI 4' off )

	if [ "$version" != "" ]; then
		version_id="${version:3:1}"

		if [ "$version_id" != "1" ]; then
			rasp_pi_version="-$version_id"
		fi
	else
		clean_up
	fi
}

init_deployer(){
	#select_rasp_pi_version
	#if [ $quit_mode -eq 0 ]; then
	#download_image
	#unpack_image
	#fi
	choose_disks
}


### INIT ####

check_dependencies
init_deployer

