#!/usr/bin/env bash
#
# This file is part of make python project, a simple script to build my baselines.
# Copyright © 2016 seamus tuohy, <code@seamustuohy.com>
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
#set -e
set -u

# TODO remove DEBUGGING
set -x

# Read Only variables

#readonly PROG_DIR=$(readlink -m $(dirname $0))
#readonly readonly PROGNAME=$(basename )
#readonly PROGDIR=$(readlink -m $(dirname ))


main() {
    project_name=$1
    mkdir ${project_name}
    cd ${project_name}
    mkdir ${project_name}
    touch ${project_name}/__init__.py
    mkdir bin
    mkdir docs
    mkdir tests
    echo "${README_TEXT}" > README.md
    touch INSTALL.md
    touch requirements.txt
    curl https://www.gnu.org/licenses/lgpl-3.0.md > LICENSE
    curl https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore > .gitignore
}

read -d '' README_TEXT <<"EOF"
# [PROJECT_NAME]

[DELETE]=> minimal, straightforward description that helps you decide whether this project is worth your time

[PROJECT_NAME] is a [WHAT], written in Python [WHY].

# Features

[DELETE]=> List of features

# Requirements

[DELETE]=> Requirements

# Installation

[DELETE]=> installation instructions

# Usage

[DELETE]=> This is the entree. “Usage” sections of readmes should detail the project’s features, interface, caveats, gotchas, tips, etc. Everything a stranger needs to solve problems with your project.

# Contribute

# License

Please see the [license file](./LICENSE) for license information on [PROJECT_NAME]. If you have further questions related to licensing PLEASE create an issue about it on github.

EOF

cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT

main ${1}
