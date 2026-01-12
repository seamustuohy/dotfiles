#!/usr/bin/env bash
#
# Copyright © 2021 seamus tuohy, <code@seamustuohy.com>
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
set -x

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "BASH_SOURCE[0]" )" && pwd )"



main() {
    mkdir -p ${HOME}/dotfiles/private/email/afew/
    echo $'# Automatically composed from other files.\n# DO NOT EDIT THIS CONFIG BY HAND!\n# See: dotfiles/bin/compose_afew_config.sh files this is built from you can edit' > ${HOME}/dotfiles/private/email/afew/config
    # Add the header
    cat ${HOME}/dotfiles/config/afew/config  \
        >> ${HOME}/dotfiles/private/email/afew/config
    cat ${HOME}/dotfiles/private/email/afew/config
    # Add all the custom rules for various inboxes
    add_custom
    # Add the footer
    echo $'\n# Items still marked as new go into the inbox\n[InboxFilter]' >> \
        ${HOME}/dotfiles/private/email/afew/config
}

add_custom() {
    while IFS= read -r -d $'\0' line ; do
        file="${line#* }";
        cat "${file}" >> ${HOME}/dotfiles/private/email/afew/config ;
    done < <(find "${HOME}/dotfiles/private/email/afew/" \
                  -type f \
                  -name "*_rules.conf" \
                  -printf '%T@ %p\0' \
                  2>/dev/null \
                 | sort -z -n)
}

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT


main
# add_custom
