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
readonly ACCOUNT_DATA="${HOME}/dotfiles/private/mutt_accounts/"

while getopts a:mu option
do
    case "${option}"
    in
        a) readonly MAILBOX_NAME=${OPTARG}
           readonly MAILBOX_DIR="${HOME}/.mail/${MAILBOX_NAME}"
           readonly MAILBOX_INFO="${ACCOUNT_DATA}/${MAILBOX_NAME}/mailbox.gpg";;
        m) readonly ACTION="MOUNT";;
        u) readonly ACTION="UNMOUNT";;
    esac
done

main() {
    # Get Mailbox Information
    printf "GPG Password for Mailbox"
    /home/s2e/dotfiles/bin/gpg-file-encrypted-to.sh "${MAILBOX_INFO}"
    exit
    source <(gpg -qd "${MAILBOX_INFO}")
    # Check if mailbox already mounted
    check_mounted

    if [[ "${ACTION}" == "MOUNT" ]]
    then
        # Check if mailbox already mounted
        if [[ "${STATE}" == "MOUNTED" ]]
        then
            # Yes - Break
            echo "Mailbox already mounted. Exiting..."
            exit 1
        else
           # No - Decrypt and mount mailbox
           mount_mailbox
        fi
    else if [[ "${ACTION}" == "UNMOUNT" ]]
         then
             # Check if mailbox is mounted
             if [[ "${STATE}" == "MOUNTED" ]]
             then
                 # Yes - Unmount
                 unmount_mailbox
             else
                 # No - Break
                 echo "Mailbox already mounted. Exiting..."
                 exit 0
             fi
         fi
    fi
}

check_mounted() {
    if grep -qs "${MAILBOX_DIR}" /proc/mounts; then
        STATE="MOUNTED"
    else
        STATE="NOT MOUNTED"
        mkdir -p "${MAILBOX_DIR}"
    fi
}

mount_mailbox() {
    echo "Mounting Mailbox"
    for raw_string in "${encrypted_volumes[@]}"
    do
        # NOTE: Password can't have colons in it or this will break
        # The path of the encrypted volume to mount
        local enc_volume_path=${raw_string%%:*}
        local path_and_pass=${raw_string#*:}
        # The local path to mount it to
        local local_path=${path_and_pass%%:*}
        local password=${path_and_pass#*:}
        # Mount volumes using veracrypt
        sudo veracrypt \
            --text \
            --verbose \
            --protect-hidden=no \
            --pim=0 \
            --keyfiles="" \
            --password="${password}" \
            --fs-options="async" \
            "$enc_volume_path" \
            "$local_path"
        sudo chown -R "$(id -u).$(id -g)" "$local_path"
    done
}

unmount_mailbox() {
    echo "Unmounting Mailbox"
    for raw_string in "${encrypted_volumes[@]}"
    do
        # NOTE: Password can't have colons in it or this will break
        local path_and_pass=${raw_string#*:}
        # The local path to mount it to
        local local_path=${path_and_pass%%:*}
        # Unmount volumes using veracrypt
        sync
        sudo veracrypt \
             --text \
             --verbose \
             --dismount \
             "$local_path"
    done
}

unmount_all() {
    echo "Dismounting ALL Veracrypt Drives"
    veracrypt -d
}

list_mounted() {
    echo "List of mounted Veracrypt Drives"
    veracrypt -t -l
}

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT

main
