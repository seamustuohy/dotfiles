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

# Setup

#Bash should terminate in case a command or chain of command finishes with a non-zero exit status.
#Terminate the script in case an uninitialized variable is accessed.
#See: https://github.com/azet/community_bash_style_guide#style-conventions
set -e
set -u

# TODO remove DEBUGGING
#set -x

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "BASH_SOURCE[0]" )" && pwd )"

readonly MAX=$(cat /sys/class/backlight/intel_backlight/max_brightness)
CURRENT=$(cat /sys/class/backlight/intel_backlight/brightness)

main() {
    local cmd=$(printf "Max\nDarken\nBrighten" | dmenu -l 21)

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi
    printf "Changing Brightness to "

    if [[ $cmd == "Max" ]]; then
        makeMax
    elif [[ $cmd == "Darken" ]]; then
        darken
    elif [[ $cmd == "Brighten" ]]; then
        brighten
    fi
    getCurrent
    printf "Brightness is ${CURRENT} out of ${MAX}\n"

}

makeMax() {
    echo ${MAX} | sudo tee /sys/class/backlight/intel_backlight/brightness
}

darken() {
    echo "${CURRENT}-100" | bc \
        | sudo tee /sys/class/backlight/intel_backlight/brightness
}

brighten() {
    echo "${CURRENT}-100" | bc \
        | sudo tee /sys/class/backlight/intel_backlight/brightness
}

getCurrent() {
    CURRENT=$(cat /sys/class/backlight/intel_backlight/brightness)
}

getMax() {
    MAX=$(cat /sys/class/backlight/intel_backlight/max_brightness)
}

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT

main
