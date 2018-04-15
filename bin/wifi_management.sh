#!/usr/bin/env bash
#
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

#Bash should terminate in case a command or chain of command finishes with a non-zero exit status.
#Terminate the script in case an uninitialized variable is accessed.
#See: https://github.com/azet/community_bash_style_guide#style-conventions
set -e
set -u

# TODO remove DEBUGGING
# set -x

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

reset_wifi_with_changed_mac() {
    # Must be run as Sudo
    # Use source_as_root in .alias to run

    # Make sure I installed macchangeer
    local mac_exists=$(which macchanger) || ""
    if [ "${mac_exists}" == "" ]; then
        printf %s "You don't have MacChanger installed. Please install it."
        exit
    fi

    # Get wireless information needed from current connection
    local iface=$(iw dev | grep Interface |cut -d " " -f 2)
    local nm_ids=$(nmcli -t --fields UUID,NAME,DEVICE connection show --active \
                          | grep "${iface}")
    local nm_UUID=$(echo "${nm_ids}" | cut -d ":" -f 1)
    local nm_NAME=$(echo "${nm_ids}" | cut -d ":" -f 2)
    local current_wifi=$(nmcli -t --fields 802-11-wireless.ssid connection show \
                               "${nm_UUID}")
    # change mac address
    ip link set dev "${iface}" down
    macchanger -r wlan0
    ip link set dev "${iface}" up

    # Setup new connection
    local new_mac=$(iw dev |grep -E "addr" |cut -d " " -f 2)
    nmcli connection modify "${nm_UUID}" 802-11-wireless.mac-address "${new_mac}"
    nmcli connection reload
}

sudo reset_wifi_with_changed_mac
