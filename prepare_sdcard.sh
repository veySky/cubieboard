#! /usr/bin/env sh

set -x
set -e

#############
# VARIABLES #
#############

# Including users defined variables
. ./makefile.vars

############
# FUNCTION #
############

format_sdcard()
{
    # is the variable set?
    if [ -n "$SDCARD_DEVICE" ] ;then
	# is the file a block device?
	if [ -b "$SDCARD_DEVICE" ] ;then
	    # shall we format the sdcard?
	    if [ "XYES" == "X$FORMAT_SDCARD" ]
	    then
		echo "n
p
1


w
" | fdisk "$SDCARD_DEVICE"
		mkfs.ext2 "$SDCARD_DEVICE"
	    else
                # We should define what "correctly" means here.
		echo "Not formating \"$SDCARD_DEVICE\" device. I assume you already did it correctly."
	    fi
            # format the first 1M of the ssdcard to write fresh bootloader there
	    dd if=/dev/zero of=$SDCARD_DEVICE bs=1k count=1025
	fi
    fi
}

########

copy2sdcard()
{
# copy boot binaries to the sdcard
    # Should match a device regexp or something like that.
    if [ -n "$SDCARD_DEVICE" ] ;then
	if [ -n "$SDCARD_DEVICE" ]
	then
	    cd u-boot-sunxi
	    sudo dd if=spl/sunxi-spl.bin of=$SDCARD_DEVICE bs=1024 seek=8
	    sudo dd if=u-boot.bin of=$SDCARD_DEVICE bs=1024 seek=32
	    cd ..

# copy root_fs to the sdcard
	    sudo mount "$SDCARD_DEVICE"1 /mnt
	    cd chroot-armhf
	    sudo bash -c "tar --exclude=qemu-arm-static -cf - . | tar -C /mnt -xvf -"
	    cd ..
	    sudo umount /mnt
	fi
    fi
}

########
# MAIN #
########

case "$1" in
    all)
	format_sdcard
	copy2sdcard
	;;
    format)
	format_sdcard
	;;
    copy2sdcard)
	copy2sdcard
	;;
    *)
	echo "Usage: prepare_sdcard.sh {all|format|copy2sdcard}"
	exit 1
esac

exit 0

########
