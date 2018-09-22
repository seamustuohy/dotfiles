#!/usr/bin/env bash
#
# This file is part of my configs.
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


DEBUG="FALSE"
while getopts d option
do
    case "${option}"
    in
        d) DEBUG="TRUE";;
    esac
done

main() {
    EMAIL_ACCOUNT=$(find ${HOME}/dotfiles/private/mutt_accounts/* -type d -printf '%f\n' | dmenu -p 'Choose Mutt account to open'  -l 21)
    # subshell so we dont overwrite variables
    (
        echo "Using Email Account: ${EMAIL_ACCOUNT}"
        export EMAIL_ACCOUNT="${EMAIL_ACCOUNT}"

        /home/s2e/dotfiles/bin/decrypt_mailbox.sh -m \
                                                  -a "${EMAIL_ACCOUNT}"
        # Q: Why torify mutt?
        # A: To remove the "Received: from" IP address leakage problem.
        #    Not expecting it does more than that
        #    See: tor wiki for info about how difficult this problem is.
        if [[ "${DEBUG}" == "TRUE" ]]
        then
               torify neomutt -d5 2>/dev/null
        else
            torify neomutt 2>/dev/null
        fi
    )
}


cleanup() {
    # put cleanup needs here
    echo "Unmounting Mailbox..."
    /home/s2e/dotfiles/bin/decrypt_mailbox.sh -u \
                                              -a "${EMAIL_ACCOUNT}"
    exit 0
}

trap 'cleanup' EXIT

main
