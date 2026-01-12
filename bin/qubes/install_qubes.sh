#!/usr/bin/env bash
#
# Copyright © 2023 seamus tuohy, <code@seamustuohy.com>
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
set -o pipefail

# TODO remove DEBUGGING
set -x

check_is_sudo() {
        if [ "$EUID" -ne 0 ]; then
                echo "Please run as root."
                exit
        fi
}

fail_is_sudo() {
        if [ "$EUID" -eq 0 ]; then
                echo "Please don't run as root."
                exit
        fi
}

# Choose a user account to use for this installation
get_user() {
    if [ -z "${TARGET_USER-}" ]; then
       PS3='Which user account should be used? '
       options=($(find /home/* -maxdepth 0 -printf "%f\n" -type d))
       select opt in "${options[@]}"; do
           readonly TARGET_USER=$opt
           break
       done
    fi
}

setup_emacs_snippets() {
    # Create emacs config dir
    local CONF_DIR="${HOME}/.emacs.d"
    mkdir -p "${HOME}/.emacs.d"

    # Add snippets
    local SNIPPET_DIR
    SNIPPET_DIR="${CONF_DIR}/snippets"
    rmdir "${SNIPPET_DIR}" || true
    if [[ ! -e "${SNIPPET_DIR}" ]]; then
        ln -snf "${HOME}/dotfiles/etc/snippets" "${SNIPPET_DIR}"
    fi
}

setup_emacs_config_links() {
    cd ~/
    ln -sf dotfiles/config/.emacs ~/.emacs
}

setup_emacs_as_editor() {
    sudo update-alternatives --install /usr/bin/editor editor "$(which emacs)" 60
    sudo update-alternatives --config editor
}

setup_config_dotfile_links() {
    cd ~/
    ln -sf dotfiles/config/.bashrc
    ln -sf dotfiles/config/.bash_profile
    ln -sf dotfiles/config/.bash_alias
    ln -sf dotfiles/config/.inputrc
    ln -sf dotfiles/config/.mailcap
    ln -sf dotfiles/config/.tmux.conf
    ln -sf dotfiles/config/.gitconfig
    ln -sf dotfiles/config/.Xmodmap
}

setup_links_to_user_scripts() {
    cd /usr/local/bin/
    sudo ln -sf $(realpath ~/dotfiles/bin/git-churn)
    sudo ln -sf $(realpath ~/dotfiles/bin/git-contributor)
    sudo ln -sf $(realpath ~/dotfiles/bin/git-release)
    sudo ln -sf $(realpath ~/dotfiles/bin/grep-xml)
    sudo ln -sf $(realpath ~/dotfiles/bin/internationalized_domain_name_decoder.py)
    sudo ln -sf $(realpath ~/dotfiles/bin/make_python_project.sh)
    sudo ln -sf $(realpath ~/dotfiles/bin/get-random-words)
    sudo ln -sf $(realpath ~/dotfiles/bin/remove_docx_protection.py)
    sudo ln -sf $(realpath ~/dotfiles/bin/rip_apk)
    sudo ln -sf $(realpath ~/dotfiles/bin/scrape_links_with_text_by_filetype.py)
    sudo ln -sf $(realpath ~/dotfiles/bin/site_info)
    sudo ln -sf $(realpath ~/dotfiles/bin/get-text-from-url)
}


first_boot() {
    setup_config_dotfile_links
    setup_links_to_user_scripts
    setup_emacs_config_links
    setup_emacs_snippets
    setup_emacs_as_editor
}


# Choose a user account to use for this installation
main() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi

    if [[ $cmd == "firstboot" ]]; then
        fail_is_sudo
        first_boot
    elif [[ $cmd == "bins" ]]; then
        fail_is_sudo
        setup_links_to_user_scripts
    else
        usage
    fi
}

cleanup() {
    # put cleanup needs here
    exit 0
}


trap 'cleanup' EXIT

main "$@"
