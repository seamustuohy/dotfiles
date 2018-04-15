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
set -x

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "BASH_SOURCE[0]" )" && pwd )"

readonly ADB_PATH="/home/s2e/temp/platform-tools"
readonly ENJARIFY_PATH="/home/s2e/code/enjarify"


main() {
    local package_name
    local package_path
    cd $ADB_PATH
    package_name=$(./adb shell pm list packages |grep -i "${1}" | cut -d: -f2|tr -d '\r')
    package_path=$(./adb shell pm path "${package_name}" | cut -d: -f2|tr -d '\r')
    ./adb pull "${package_path}" "${2}/"
    cd $ENJARIFY_PATH
    python3 -O -m enjarify.main "${2}/base.apk" -f -o "${2}/base-enjarify.jar"
}


cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT


# get_apk.sh [apkid] [working_path]
# apkid           a string that is likely to be in the apk name but not in other apk names
# working_path    a path where the files should be placed
main "${1}" "${2}"
