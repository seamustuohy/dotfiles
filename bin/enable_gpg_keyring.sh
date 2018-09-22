#!/usr/bin/env bash
#
# This file is part of my dotfiles.
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
# set -u

# TODO remove DEBUGGING
# set -x

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "BASH_SOURCE[0]" )" && pwd )"



main() {
    unlock=$(printf "Yes\nNo" | dmenu -l 2 -p "Do you want to unlock a PGP key?")
    if [[ "Yes" == "${unlock}" ]]; then
        secret_keys=""
        get_secret_keys
        key_to_unlock=$(printf "${secret_keys}" | dmenu -l 21 -p "Choose the PGP key to unlock"| cut -d: -f1)
        echo "Unlocking Key : ${key_to_unlock}"
        echo "random string" | gpg -ear "${key_to_unlock}" | gpg -d 1>/dev/null
    fi
}

add_new_key() {
    if [[ -z "${secret_keys}" ]]; then
        secret_keys="${keystring}"
    else
        secret_keys="${secret_keys}\n${keystring}"
    fi
}

get_secret_keys() {
    IFS=$'\n'
    local sec_keys
    sec_keys=$(gpg --with-colons --list-secret-keys | grep -E "^[su][ue][uc][i]*.*" | cut -d: -f 2,5,7)
    unset IFS
    # declare -A keystrings
    for shortkey in $sec_keys; do
        get_keystring "${shortkey}"
    done
}

get_keystring() {
        local keystring=""
        local keyid=$(echo $shortkey | cut -d: -f 2)
        keystring="0x${keyid}:"
        # echo "${keystring}"
        # Is Expired?
        if [[ $shortkey = "e"* ]]; then
            keystring="${keystring} [EXPIRED] -"
        else
            keystring="${keystring}           -"
        fi
        # echo "${keystring}"
        ## Get UID's for Key
        IFS=$'\n'
        local emails=$(gpg --list-keys $keyid | grep "^uid" | cut -d: -f10 | sed 's/.*<\(.*\)>.*/\1/')
        unset IFS
        ## Get Domains for key
        declare -A domains
        for email in $emails; do
            # echo "$email"
            local domain=($(echo $email| cut -d@ -f2))
            #echo $domain
            local host=($(echo $email| cut -d@ -f1))
            # Check if key exist in array
            local cur_domain=$(echo "${domains[$domain]}")
            if [[ -z $cur_domain ]]; then
                # echo "EMPTY"
                # Create new [host]@[domain] string
                domains["${domain}"]="[${host}]@${domain}"
                # echo "${host}"
                # echo "${domains[$domain]}"
            else
                # Add [host2] to [host1]@[domain]
                # Create [host2][host1]@[domain]
                domains["${domain}"]="[${host}]${cur_domain}"
                # echo "${host}"
                # echo "${domains[$domain]}"
            fi
        done
        # Create Domain Strings
        local domain_strings=""
        for i in "${!domains[@]}"; do
            if [[ -z $domain_strings ]]; then
                domain_strings="${domains[$i]}"
            else
                domain_strings="${domain_strings}; ${domains[$i]}"
            fi
        done
        keystring="${keystring} ${domain_strings}"
        add_new_key "${keystring}"
}

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT


main
