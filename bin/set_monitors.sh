#!/usr/bin/env bash
#
# This file is part of package name, a package description short.
# Copyright © 2017 seamus tuohy, <s2e@seamustuohy.com>
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

main() {
    local monitor_num=$(xrandr |grep " connected" |wc -l)
    local desk_horiz=$(xrandr |grep -E "^DP-2-2 connected" |wc -l)
    local desk_2020=$(xrandr |grep -E "^DP-2-3 connected" |wc -l)
    local desk_vert=$(xrandr |grep -E "^DP-1 connected" |wc -l)
    local work_left=$(xrandr |grep -E "^DP-2 connected" |wc -l)

    if [[ 1 == ${work_left} ]] ; then
        echo "Work Connected"
    fi
    if [[ 1 == ${desk_horiz} ]] ; then
        echo "Horizontal Connected"
    fi
    if [[ 1 == ${desk_vert} ]] ; then
        echo "Vertical Connected"
    fi

    elif [[ 1 == ${desk_2020} ]]  ; then
        2020_setup
    fi

    if [[ 1 == ${desk_horiz} ]] && [[ 1 == ${desk_vert} ]] ; then
        desktop_setup
    elif [[ 1 == ${desk_horiz} ]] && [[ 1 != ${desk_vert} ]] ; then
        lap_plus_horiz_setup
    elif [[ 1 != ${desk_horiz} ]] && [[ 1 == ${desk_vert} ]] ; then
        lap_plus_vert_setup
    elif [[ 1 == ${work_left} ]]  ; then
        setup_work
    elif [[ 2 == ${monitor_num} ]]  ; then
        external_setup
    else
        xrandr --auto
    fi
}

2020_setup(){
    xrandr --output DP-2-3 --auto
    xrandr --output eDP-1 --rotate normal --auto --right-of DP-2-3
}

setup_work() {
    xrandr --output DP-2 --auto
    xrandr --output eDP-1 --rotate normal --auto --left-of DP-2
    # xrandr --output eDP-1 --off
}

desktop_setup() {
    xrandr --output eDP-1 --auto || true
    xrandr --output DP-2-2 --mode 1920x1080 --primary --left-of eDP-1
    xrandr --output DP-1 --rotate normal --auto --left-of DP-2-2
    xrandr --output eDP-1 --off
}

lap_plus_horiz_setup() {
    xrandr --output eDP-1 --mode 1600x900
    xrandr --output DP-2-2 --mode 1920x1080 --primary --output eDP-1 --mode 1600x900 --left-of DP-2-2
}

lap_plus_vert_setup() {
    local laptop_monitor="eDP-1"
    local primary_mon=$(xrandr |grep -E "^DP-2-2 connected" |wc -l)
    local second_mon=$(xrandr | \
                       grep " connected" | \
                       grep -v "${laptop_monitor}" | \
                       cut -d " " -f 1)
    xrandr --output "${laptop_monitor}" --auto
    xrandr --output "${second_mon}" --auto --right-of "${laptop_monitor}"
}

external_setup() {
    local laptop_monitor="eDP-1"
    local primary_mon=$(xrandr |grep -E "^DP-2-2 connected" |wc -l)
    local second_mon=$(xrandr | \
                       grep " connected" | \
                       grep -v "${laptop_monitor}" | \
                       cut -d " " -f 1)
    xrandr --output eDP-1 --auto
    xrandr --output "${second_mon}" --auto --right-of "${primary_mon}"
}

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT


main
