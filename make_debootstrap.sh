#! /usr/bin/env sh

#set -x
set -e

#############
# VARIABLES #
#############

HOSTNAME=A10
PACKAGES="emacs23-nox"
LINUX_DIR=../linux-stable/
CHROOT_DIR=chroot-armhf

############
# FUNCTION #
############

do_debootstrap()
{
set -x

sudo /usr/sbin/debootstrap --foreign --arch armhf wheezy .

# that command is usefull to run target host binaries (ARM) on the build host  (x86)
sudo cp /usr/bin/qemu-arm-static usr/bin

# if you use grsecurity on build host, you should uncomment that line
#sudo /sbin/paxctl -cm usr/bin/qemu-arm-static
#sudo /sbin/paxctl -cpexrms usr/bin/qemu-arm-static

# debootstrap second stage and packages configuration
sudo LC_ALL=C LANGUAGE=C LANG=C chroot . /debootstrap/debootstrap --second-stage
sudo LC_ALL=C LANGUAGE=C LANG=C chroot . dpkg --configure -a

set +x
}

##########

configure_system()
{
# set root password
echo "Please enter the root password: "
sudo chroot . passwd

# set hostname
echo -n "Please enter the hostname of the host: "
read HOSTNAME
sudo bash -c "echo $HOSTNAME > etc/hostname"

set -x

# add serial console to connect to the system
sudo bash -c 'echo "T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100" >> etc/inittab'

set +x
}

##########

update_system_and_custom_packages()
{
    set -x

# tmp stuff
    sudo cp /etc/resolv.conf etc

# updating root_fs
    sudo bash -c "echo deb http://http.debian.net/debian/ wheezy main contrib non-free > etc/apt/sources.list"
    sudo bash -c "echo deb http://security.debian.org/ wheezy/updates main contrib non-free >> etc/apt/sources.list"
    sudo chroot . apt-get update
    sudo chroot . apt-get upgrade

# install additionnals packages
    sudo chroot . apt-get install "$PACKAGES"

# removing tmp stuff
    sudo chroot . apt-get clean
    sudo chroot . apt-get autoclean
    sudo rm etc/resolv.conf

    set +x
}

##########

install_kernel()
{
    set -x
# copy linux image to the root_fs
    sudo cp $LINUX_DIR/arch/arm/boot/uImage boot
    sudo make -C $LINUX_DIR INSTALL_MOD_PATH=`pwd` ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install

# add some kernel boot args
    mkimage -C none -A arm -T script -d ../boot.cmd ../boot.scr
    sudo mv ../boot.scr boot/
    sudo chown root:root boot/boot.scr
    set +x
}

##########

board_script()
{
    set -x
    ../sunxi-tools/fex2bin ../sunxi-boards/sys_config/a10/cubieboard.fex ../script.bin
    sudo chown root:root ../script.bin
    sudo mv ../script.bin boot/
    set +x
}

########
# MAIN #
########

# create the chroot if it doesn't exist
mkdir -p $CHROOT_DIR
cd $CHROOT_DIR

case "$1" in
    all)
	do_debootstrap
	configure_system
	update_system_and_custom_packages
	install_kernel
	board_script
	;;
    debootstrap)
	do_debootstrap
	;;
    config)
	configure_system
	;;
    custom)
	update_system_and_custom_packages
	;;
    kernel)
	install_kernel
	;;
    board_script)
	board_script
	;;
    *)
	echo "Usage: make_debootstrap.sh {all|debootstrap|config|custom|kernel|board_script}"
	exit 1
esac

exit 0

##########
