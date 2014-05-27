#!/bin/bash

previous="/tmp/dev-setup"
uefi="/sys/firmware/efi"
vbox_chk="$(hwinfo --gfxcard | grep -o -m 1 "VirtualBox")"
notify="$1"
notify_user () {
    if [[ "${notify}" -eq "-n" ]]; then
        notify-send -a "Cnchi" -i /usr/share/cnchi/data/images/antergos/antergos-icon.png "$1"
    fi
}

# Check if this is the first time we are executed.
if ! [ -f "${previous}" ]; then
	touch ${previous};
	# Find the best mirrors (fastest and latest)
    notify_user "Selecting the best mirrors..."
	echo "Selecting the best mirrors..."
	echo "Testing Arch mirrors..."
	reflector -p http -l 30 -f 5 --save /etc/pacman.d/mirrorlist;
	echo "Done."
	sudo -u antergos wget http://antergos.info/antergos-mirrorlist
	echo "Testing Antergos mirrors..."
	rankmirrors -n 0 -r antergos antergos-mirrorlist > /tmp/antergos-mirrorlist
	cp /tmp/antergos-mirrorlist /etc/pacman.d/
	echo "Done."
	# Install any packages that haven't been added to the iso yet but are needed.
	notify_user "Installing missing packages..."
	echo "Installing missing packages..."
	# Check if system is UEFI boot.
	if [ -d "${uefi}" ]; then
		pacman -Syy git --noconfirm --needed;
	else
		pacman -Syy git --noconfirm --needed;
	fi
	# Enable kernel modules and other services
	if [[ "${vbox_chk}" -eq "VirtualBox" ]] && [[ -d "${uefi}" ]]; then
	    notify_user "VirtualBox detected. Checking kernel modules and starting services."
		echo "VirtualBox detected. Checking kernel modules and starting services."
		modprobe -a vboxsf f2fs efivarfs dm-mod && systemctl start vboxservice;
	elif [[ "${vbox_chk}" -eq "VirtualBox" ]]; then
		modprobe -a vboxsf f2fs dm-mod && systemctl start vboxservice;
	else
		modprobe -a f2fs dm-mod;
	fi
	# Update Cnchi with latest testing code
	echo "Removing existing Cnchi..."
	rm -R /usr/share/cnchi;
	cd /usr/share;
	notify_user "Getting latest version of Cnchi from testing branch..."
	echo "Getting latest version of Cnchi from testing branch..."
	# Check commandline arguments to choose repo
	if [[ "$1" != "-n" ]]; then
	    if [[ "$1" -eq "-d" ]] || [[ "$1" -eq "--dev-repo" ]]; then
		    git clone https://github.com/"$2"/Cnchi.git cnchi;
		fi
	elif [[ "$1" -eq "-n" ]]; then
	    if [[ "$2" -eq "-d" ]] || [[ "$2" -eq "--dev-repo" ]]; then
		    git clone https://github.com/"$3"/Cnchi.git cnchi;
		fi
	else
		git clone https://github.com/Antergos/Cnchi.git cnchi;
	fi
	cd /usr/share/cnchi
	
else
    notify_user "Previous testing setup detected, skipping downloads..."
	echo "Previous testing setup detected, skipping downloads..."
	notify_user "Verifying that nothing is mounted from a previous install attempt."
	echo "Verifying that nothing is mounted from a previous install attempt."
	umount -lf /install/boot >/dev/null 2&>1
	umount -lf /install >/dev/null 2&>1
	# Check for changes on github since last time script was executed
	# Update Cnchi with latest testing code
	notify_user "Getting latest version of Cnchi from testing branch..."
	echo "Getting latest version of Cnchi from testing branch..."
	cd /usr/share/cnchi
	git pull origin master;
fi

# Start Cnchi with appropriate options
notify_user "Starting Cnchi..."
echo "Starting Cnchi..."
# Are we using an alternate PKG cache?
# TODO Remove this nonsense and use proper command argument processing
if [[ "$1" != "-n" ]] && [[ "$1" != "" ]]; then
    if [[ "$1" -eq "-d" ]] || [[ "$1" -eq "--dev-repo" ]] || [[ "$1" -eq "-z" ]]; then
        cnchi -d -v -z -p /usr/share/cnchi/data/packages.xml & exit 0;
    else
        cnchi -d -v -p /usr/share/cnchi/data/packages.xml & exit 0;
    fi
elif [[ "$1" -eq "-n" ]]; then
    if [[ "$2" -eq "-d" ]] || [[ "$2" -eq "--dev-repo" ]] || [[ "$2" -eq "-z" ]]; then
        cnchi -d -v -z -p /usr/share/cnchi/data/packages.xml & exit 0;
    else
        cnchi -d -v -p /usr/share/cnchi/data/packages.xml & exit 0;
    fi
else
     cnchi -d -v  -p /usr/share/cnchi/data/packages.xml & exit 0;
fi


exit 1;
