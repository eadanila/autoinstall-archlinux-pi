#!/bin/bash

# Automation of the install instructions for AArch 64 found at:
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4

function usage() {
    echo Usage: $0 /dev/sdX
    exit $1
}

function verify_exit() {
    if [[ $1 -ne 0 ]]; then
        echo $2
        exit $3
    fi
}

if [[ $# -ne 1 ]]; then
    echo Invalid number of arguments
    usage 1
fi
if [[ $1 != /dev/sd* ]]; then
    echo Invalid device: $1
    usage 2
fi
if [[ ! -e $1 ]]; then
    echo Device not found: $1
    usage 3
fi

if [[ `id -u` -ne 0 ]]; then
    echo "This script needs root permssions to interact with block devices. Please run as root."
    exit 4
fi

TGTDEV=$1
echo Partitioning $1...
sfdisk $TGTDEV < alarm.sfdisk
verify_exit $? "Partitioning $TGTDEV failed" -1

BOOTPART=$11
echo Formatting $BOOTPART as vfat...
yes | mkfs.vfat $BOOTPART -n boot
verify_exit $? "Formatting $BOOTPART failed" -2

ROOTPART=$12
echo Formatting $ROOTPART as ext4...
yes | mkfs.ext4 $ROOTPART -L root
verify_exit $? "Formattinging $ROOTPART failed" -2


# Paranoid amount of verifying the temp directory,
# but if it ends up being in the wrong place we could
# end up woring in /
echo Setting up temporary directory...
TMP=`mktemp -d`
if [[ ! -d $TMP ]]; then
    echo $TMP does not exist
    exit -4
fi
if [[ $TMP/ != /tmp/* ]]; then
    echo $TMP not in /tmp
    exit -5
fi
if find $TMP -mindepth 1 | read; then
    echo $TMP not empty
    exit -6
fi
BOOT=$TMP/boot
ROOT=$TMP/root
mkdir $BOOT
mkdir $ROOT


echo Mounting $BOOTPART to $BOOT...
mount $BOOTPART $BOOT
verify_exit $? "Mounting $BOOTPART failed" -7

echo Mounting $ROOTPART to $ROOT...
mount $ROOTPART $ROOT
verify_exit $? "Mounting $ROOTPART failed" -8

echo Downloading http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz...
curl -L http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz > $TMP/alarm.tar.gz
verify_exit $? "Downloading tarball failed" -9

echo Extracting $TMP/alarm.tar.gz...
bsdtar -xpf $TMP/alarm.tar.gz -C $ROOT
verify_exit $? "Extracting tarball failed" -10
mv $TMP/root/boot/* $BOOT

echo Updating fstab...
sed -i 's/mmcblk0/mmcblk1/g' $ROOT/etc/fstab
verify_exit $? "Updating fstab failed" -11

echo Synchronizing partitions...
sync

echo Unmounting partitions...
umount $BOOT $ROOT
verify_exit $? "Failed to umount partitions" -12

# Verify temp directory again because we're about to
# rm -r $TMP and we definitely don't want to accidentally
# rm some random directory (especially if that directory
# is /)
echo Cleaning up...
if [[ ! -d $TMP ]]; then
    echo $TMP does not exist
    exit -13
fi
if [[ $TMP/ != /tmp/* ]]; then
    echo $TMP not in /tmp
    exit -14
fi
rm -r $TMP

echo Done

