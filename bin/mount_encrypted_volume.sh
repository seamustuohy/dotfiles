#!/usr/bin/env bash
#
# This file is part of package name, a package description short.
# Copyright © 2017 seamus tuohy, <code@seamustuohy.com>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the included LICENSE file for details.

# Setup

#Bash should terminate in case a command or chain of command finishes with a non-zero exit status.
#Terminate the script in case an uninitialized variable is accessed.
#See: https://github.com/azet/community_bash_style_guide#style-conventions
set -e
set -u

# TODO remove DEBUGGING
# set -x

main() {
    check_dependencies
    # Get's USB_DEVICE
    id_usb_dev
    mount_encrypted_device
}

check_dependencies() {
    printf "Checking Dependencies\n\n"
    printf "Do you see lvm2 and cryptsetup packages on the following lines?\n"
    printf "If not, you should install them.\n"
    dpkg --get-selections | grep -v deinstall | grep -E "^lvm2"
    dpkg --get-selections | grep -v deinstall | grep -E "^cryptsetup"
    sudo modprobe dm-crypt
    sudo modprobe dm-mod
}

mount_encrypted_device() {
    local CURRENT_VOLUME=$(sudo vgscan | grep "Found volume" | sed 's/Found volume group "\(.*\)".*/\1/' |  tr -d '[:space:]')
    printf "Opening Encrypted Device\n"
    printf "You will have to type in the password used to encrypt the volume\n"
    sudo cryptsetup luksOpen "/dev/${USB_DEVICE}" encrypted
    printf "Now you need to identify the encrypted devices volume group\n"
    printf "Which volume group is the one from your harddrive?\n"
    printf "i.e.\n"
    printf "Found volume group \"VOLUME-GROUP-NAME-vg\" using metadata type lvm2\n"
    printf "=================VGSCAN=====================\n"
    sudo vgscan
    printf "==============VGSCAN ENDS====================\n"
    printf "HINT: It is NOT ${CURRENT_VOLUME} \n"
    printf "Type the name and hit return: "
    read volume_group_name
    VOLUME_GROUP_NAME="$volume_group_name"
    printf "Activating that volume group...\n"
    sudo vgchange -ay "${VOLUME_GROUP_NAME}"
    printf "OK, Now we need to pick the actual logical volume within it we want to mount\n"
    printf "The names are in the LV column. They will be labeled ${VOLUME_GROUP_NAME} in the VG column.\n"
    printf "=================LVS=====================\n"
    sudo lvs
    printf "===============LVS ENDS==================\n"
    printf "Type the name and hit return: "
    read volume_name
    VOLUME_NAME="$volume_name"
    printf "OK, last step. We are making a directory for mounting the encrypted volume and then mounting it.\n"
    printf "The directory is /media/encrypted\n"
    sudo mkdir -p /media/encrypted
    printf "You can go here to access the encrypted volume.\n"
    sudo mount /dev/${VOLUME_GROUP_NAME}/${VOLUME_NAME} /media/encrypted

    printf "==========INSTRUCTIONS TO UNMOUNT =====================\n"
    printf "Type the following commands:\n"
    printf "sudo umount /media/encrypted\n"
    printf "sudo vgchange -an ${VOLUME_GROUP_NAME}\n"
    printf "sudo cryptsetup luksClose encrypted\n"
    printf "BYE!\n"
}

# [1430409.623236] usb-storage 1-3:1.0: USB Mass Storage device detected
# [1430410.653600]  sdc: sdc1 sdc2 < sdc5 >
# [1430410.654799] sd 3:0:0:0: [sdc] Attached SCSI disk
id_usb_dev() {
    printf "Plug in your hardrive reader and turn it on now.\n"
    printf "Press Return when you have done so\n"
    read
    printf "\n\n==============DMESG OUTPUT=============\n"
    sudo dmesg  | tail | grep -EB 10 "s[a-z]{2}[0-9]"
    printf "\n\n==============DMESG ENDS=============\n\n"
    printf "What is the device name of the harddrive?\n"
    printf "[ 1234.123456]  sxx: sxx1 sxx2 < !THIS ONE! >\n"
    read devname
    USB_DEVICE="$devname"
}

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT


main
