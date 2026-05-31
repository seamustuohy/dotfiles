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

# DEBUGGING
# set -x

# Read Only variables

# readonly PROG_DIR=$(readlink -m $(dirname $0))
# readonly PROGNAME="$( cd "$( dirname "BASH_SOURCE[0]" )" && pwd )"


# === GPG find who a file is encryped to ===

# List who some gpg data is encrypted to
# Only works if the client puts key IDs into encrypted packets
# But, most clients do
# Regex Snippets
#
# Match Fingerprint
# MATCHES: 0xAABBCCDD11223344
# REGEX: \(0x[A-Z0-9]\{16\}\)
#
# Match Quoted Name
# MATCHES:       "Seamus Tuohy <code@seamustuohy.com>"
# REGEX: \s*\"\([^\"]*\"\).*

main () {
    # List who a gpg encrypted file is encrypted to
    # Only works if the client puts key IDs into encrypted packets
    local FILE_PATH="$1"
    # Read file ignoring nulls
    local filedata=$(tr -d '\0' <"${FILE_PATH}")
    local encrypted_to=$(printf "%s\n" ${filedata} \
                             | gpg --batch --list-packets 2>&1 \
                             | sed -n \
                                   '/\(0x[A-Z0-9]\{16\}\)/{ # Match first line
                                   # Append next input line to contents of pattern space
                                   $!{ N
                                   # sed substitution pattern that works on merged lines
                                   s/.*\(0x[A-Z0-9]\{16\}\).*\n\s*\"\([^\"]*\"\).*/\2 - \1/
                                   # substitution successful -> goto label :found
                                   t found
                                   # substitution failed (match not found)
                                   :not-found
                                   # if no match, delete line
                                   d
                                   # substitution successful (match found)
                                   :found
                                   # print substitution for match
                                   p
                                   }
                                   }')

    if [[ -z "${encrypted_to// }" ]]; then
        local encrypted_kid=$(printf "%s\n" ${filedata} \
                                 | gpg --batch --list-packets 2>&1 \
                                 | grep -oE 'keyid [A-Z0-9]{16}' \
                                 | cut -d' ' -f2)
        if [[ -z "${encrypted_kid// }" ]]; then
            printf "%s\n" "Decrypting unknown GPG key"
            printf "%s\n" ${filedata} \
                | gpg --batch --list-packets 2>&1
        else
            echo "${encrypted_kid}" \
                | xargs -I % gpg --list-key --with-colons % \
                | grep -E "^uid*.*" | cut -d: -f 10
        fi
    else
        printf "%s\n" ${encrypted_to}
    fi
}



cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT


main "$1"
