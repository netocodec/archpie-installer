#!/bin/bash

clear

application_title="ArchPie Linux V0.1-Alpha"
rasp_pi_version=""
quit_mode=0

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

unpack_image(){
	dialog --title "$application_title" --gauge "Unpack Image..." 0 0 40 &
	mkdir root

	# IN_DEVELOPMENT
	# Enter Sudo Mode
	sudo su

	# Replace the bsdtar dependency with the "tar" dependency.

	tar -xpsf arch_image.tar.gz -C root/

	# Exit Sudo Mode
	exit
	dialog --title "$application_title" --gauge "Syncronize Image..." 0 0 60 &
	sync
}

select_rasp_pi_version(){
	version=$( dialog --stdout --title "$application_title" --radiolist "Select the raspberry pi version." \
		0 0 0 \
		RPI1 'Raspberry PI' on \
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
	select_rasp_pi_version
	if [ $quit_mode -eq 0 ]; then
		download_image
		unpack_image
	fi
}


### INIT ####

check_dependencies
init_deployer
