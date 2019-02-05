#!/usr/bin/env bash
#
# Copyright © 2018 seamus tuohy, <code@seamustuohy.com>
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

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "BASH_SOURCE[0]" )" && pwd )"

# Get list of encrypted volumes to mount from encrypted file
# readonly encrypted_volumes=("enc_vol_path:local_path")


# source <(gpg -qd ~/dotfiles/private/setup/encrypted_volumes.gpg)

main() {
    # Unmount all veracrypt to start
    mount_drives
    sync_unison
    unmount
}

mount_drives() {
    echo "Mount Archive to Veracrypt Drive 'A:' then press enter"
    read test
    echo "Mounting archive on Drive A:"
    sudo mkdir -p /mnt/A
    sudo mount -t drvfs A: /mnt/A
}

sync_unison() {
    unison  /home/s2e/library /mnt/A/library
}

unmount() {
    echo "Dismounting Veracrypt Drives"
    sync
    sudo umount /mnt/A
}

cleanup() {
    # put cleanup needs here
    echo "Don't forget to unmount the archive in windows using veracrypt"
    exit 0
}

trap 'cleanup' EXIT

main 
