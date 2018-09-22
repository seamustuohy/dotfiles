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



main() {
    while IFS= read -r -d $'\0' line ; do
        file="${line#* }"
        printf "===\t%s\t===\n\n" "Checking File: ${file}"
        xmllint --format "${file}" | grep --color "${GREP_ARG[@]}" && printf "\n\n" || printf "%s\n\n" "FOUND: None"
    done < <(find . \
                  -maxdepth "${DEPTH}" \
                  -type f \
                  -name "$FILENAME" \
                  -printf '%T@ %p\0' \
                  2>/dev/null \
                 | sort -z -n)
}


cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT

usage() {
    printf "%s\n\n%s\n\n\t%s\t%s\n\t%s\t\t%s\n\t%s\t\t%s\n\n\t%s\n" \
           "Usage: $(basename $0) [-R] [-f filename] [grep query]" \
           "Grep through xml files that have been compressed to not include newlines. Recursive by default! Mostly useful for Word documents." \
           "-f, filename" \
           "arg for find -name cmd" \
           "-R" \
           "DON'T descend into child directories."\
           "-h" \
           "Get this help info." \
           "Dependencies: grep, xmllint" >&2
    exit 1
}

FILENAME="*.xml"
DEPTH="1000"
while getopts f:g:hR option
do
    case "${option}"
    in
        R) DEPTH="1" ;;
        f) FILENAME="$OPTARG";;
        g) GREP_ARG=($OPTARG);;
        h) usage;;
        ?) usage;;
    esac
done

main
