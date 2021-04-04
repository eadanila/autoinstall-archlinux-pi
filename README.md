# pi-arch-autoinstall
A script that automates the installation process for Arch Linux Arm on a boot device for a Raspberry Pi.
Specifically, it automates [this](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4), which
works for both the Pi 3 and the Pi 4. 

Once complete, the SD (or USB) will have a 200MB FAT32 boot partition and the rest will be used for the ext4
root partition. Partition layout can be modified by changing alarm.sfdisk.

The SD should be easily portable between any version of Pi 3 and Pi 4 with the exception of AArch64 on the
8GB Pi 4. See [AArch64 on the 8GB Pi 4](#aarch64-on-the-8GB-pi-4) for a workaround.

# Usage
THIS WILL FORMAT THE DEVICE YOU TARGET WITHOUT CONFIRMATION. Be absolutely sure you have the right one before
you hit enter.

`# ./install.sh /dev/sdX [architecture]`


### Architecture
The architecture flag allows you to choose between the 32-bit and 64-bit versions.

For the ARMv7 (32-bit) version, either `armv7`, `armv7l`, and `arm32` can be specified and are treated as
synonymous. This is the default architecture.

For the AArch64 (64-bit) verison, either `aarch64` and `arm64` can be specified and are treated as synonymous.

### Examples
`# ./install.sh /dev/sdb armv7` installs the 32-bit ARMv7 version to /dev/sdb.

`# ./install.sh /dev/sdc aarch64` installs the 64-bit AArch64 version to /dev/sdc.

# AArch64 on the 8GB Pi 4
As of this writing, the default AArch64 build of Arch Linux fails to properly initialize USB on the 8GB
Pi 4. The workaround is to use either SSH or a Pi 3 or Pi 4 with less than 4GB of RAM to install the
`linux-raspberrypi4` kernel. It will replace the stock kernel. Contrary to it's name, it also seems to 
run just fine on the Pi 3, in case you want to keep your install compatible with both the Pi 3 and the
Pi 4. Once installed, reboot or reinsert the SD card into your 8GB Pi 4 and USB should work.
