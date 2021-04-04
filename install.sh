#!/bin/bash

# Automation of the install instructions for AArch 64 found at:
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
# Should also work with Pi 3.

function usage() {
    echo
    echo Usage: $0 /dev/sdX [architecture]
    echo
    echo ARCHITECTURES
    echo "    armv7, armv7l, arm32"
    echo "      Treated as synonymous for armv7l for the Pi 3 and Pi 4."
    echo "      Specifically, ArchLinuxARM-rpi-4-latest, which runs on both."
    echo
    echo "    aarch64, arm64"
    echo "      Treated as synonymous for AArch64 for the Pi 3 and Pi 4."
    echo "      Specifically, ArchLinuxARM-rpi-aarch64-latest."

    exit $1
}

function verify_exit() {
    if [[ $1 -ne 0 ]]; then
        echo $2
        exit $3
    fi
}


if [[ `id -u` -ne 0 ]]; then
    echo "This script needs root permssions to interact with block devices. Please run as root."
    exit 0
fi

if [[ $# -lt 1  || $# -gt 2 ]]; then
    echo Invalid number of arguments
    usage 1
fi
if [[ $1 != /dev/sd* ]]; then
    echo Invalid device: \'$1\'
    usage 2
fi
if [[ ! -e $1 ]]; then
    echo Device not found: \'$1\'
    usage 3
fi


# Select a target URL based on architecture
# Contrary to the name, the rpi-4 tarball works on the Raspberry Pi 3
URL=http://os.archlinuxarm.org/os
TARBALL=ArchLinuxARM-rpi-4-latest.tar.gz
ARCH=armv7l
if [[ $# -eq 2 ]]; then
    case $2 in
        armv7 | armv7l | arm32)
            URL=http://os.archlinuxarm.org/os
            TARBALL=ArchLinuxARM-rpi-4-latest.tar.gz
            ARCH=armv7l
            ;;
        aarch64 | arm64)
            URL=http://os.archlinuxarm.org/os
            TARBALL=ArchLinuxARM-rpi-aarch64-latest.tar.gz
            ARCH=aarch64
            ;;
        *)
            echo Invalid architecture \'$2\'
            usage 4
            ;;
    esac
else
    echo Assuming 32 bit Arm
fi


# Paranoid amount of verifying the temp directory,
# but if it ends up being in the wrong place we could
# end up ruining a directory. If $TMP is blank we could
# end up in /
echo Setting up temporary directory...
TMP=`mktemp -d`
if [[ ! -d $TMP ]]; then
    echo $TMP does not exist
    exit -1
fi
if [[ $TMP/ != /tmp/* ]]; then
    echo $TMP not in /tmp
    exit -2
fi
if find $TMP -mindepth 1 | read; then
    echo $TMP not empty
    exit -3
fi
BOOT=$TMP/boot
ROOT=$TMP/root
mkdir $BOOT
mkdir $ROOT


TGTDEV=$1
echo Partitioning $1...
sfdisk $TGTDEV < alarm.sfdisk
verify_exit $? "Partitioning $TGTDEV failed" -4

BOOTPART=$11
echo Formatting $BOOTPART as vfat...
yes | mkfs.vfat $BOOTPART -n boot
verify_exit $? "Formatting $BOOTPART failed" -5

ROOTPART=$12
echo Formatting $ROOTPART as ext4...
yes | mkfs.ext4 $ROOTPART -L root
verify_exit $? "Formattinging $ROOTPART failed" -6


echo Mounting $BOOTPART to $BOOT...
mount $BOOTPART $BOOT
verify_exit $? "Mounting $BOOTPART failed" -7

echo Mounting $ROOTPART to $ROOT...
mount $ROOTPART $ROOT
verify_exit $? "Mounting $ROOTPART failed" -8

echo Entering $TMP...
pushd $TMP > /dev/null 2>&1
verify_exit $? "Entering $TMP failed" -10


echo Downloading $TARBALL...
curl -OL $URL/$TARBALL --output-dir $TMP
verify_exit $? "Downloading $TARBALL failed" -11

echo Downloading $TARBALL.md5...
curl -OL $URL/$TARBALL.md5 --output-dir $TMP
verify_exit $? "Downloading $TARBALL.md5 failed" -12

echo Verifying $TARBALL...
md5sum --check $TARBALL.md5
verify_exit $? "Verifying $TARBALL failed" -13


echo Extracting $TARBALL...
bsdtar -xpf $TMP/$TARBALL -C $ROOT
verify_exit $? "Extracting tarball failed" -14
mv $TMP/root/boot/* $BOOT


echo Updating fstab...
sed -i 's/\/dev\/mmcblk0p1/LABEL=boot/g' $ROOT/etc/fstab
verify_exit $? "Updating fstab failed" -15


echo Synchronizing partitions...
sync


echo Unmounting partitions...
umount $BOOT $ROOT
verify_exit $? "Failed to umount partitions" -16


# Verify temp directory again because we're about to
# rm -r $TMP and we definitely don't want to accidentally
# rm some random directory (especially if that directory
# is /)
echo Cleaning up...
popd > /dev/null 2>&1
if [[ ! -d $TMP ]]; then
    echo $TMP does not exist
    exit -17
fi
if [[ $TMP/ != /tmp/* ]]; then
    echo $TMP not in /tmp
    exit -18
fi
rm -r $TMP


# Instructions and notes
if [[ $ARCH = aarch64 ]]; then
    echo
    echo Note: As of 3 April 2021, the AArch64 kernel does not properly initialize
    echo USB on the 8GB Pi 4. Until this is fixed, the workaround is to install the
    echo \`linux-raspberrypi4\` kernel. Contrary to the name, this kernel also works
    echo on the Pi 3. Use either SSH or a Pi 3/Pi 4 with less than 8GB of RAM to do
    echo the install, as you will not have a working keyboard until you do.
    echo
fi
echo Default user $(tput bold)alarm$(tput sgr0) with password $(tput bold)alarm$(tput sgr0).
echo Default $(tput bold)root$(tput sgr0) password is $(tput bold)root$(tput sgr0).
echo Remember to run \`pacman-key --init\` and \`pacman-key --populate archlinuxarm\`


echo
echo Done

