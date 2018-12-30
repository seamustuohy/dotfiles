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
# set -u
set -o pipefail

# TODO remove DEBUGGING
set -x

# Read Only variables

# readonly TARGET_USER=$(basename "$HOME")
readonly SOURCE_DIR="/usr/local/src"

if [[ -e "/usr/local/src/install_helpers" ]]; then
    source /usr/local/src/install_helpers
else
    echo "Run makefile to move install_helpers into sources"
fi


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

setup_sources() {
        sudo apt-get update
        sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                dirmngr \
                --no-install-recommends

        sudo apt-get update
        sudo cat <<-EOF > /etc/apt/sources.list

deb https://deb.debian.org/debian testing main contrib non-free
deb-src https://deb.debian.org/debian testing main contrib non-free

deb https://deb.debian.org/debian testing-updates main contrib non-free
deb-src https://deb.debian.org/debian testing-updates main contrib non-free

deb https://deb.debian.org/debian-security testing/updates main contrib non-free
deb-src https://deb.debian.org/debian-security testing/updates main contrib non-free

deb http://www.deb-multimedia.org testing main non-free
deb-src http://www.deb-multimedia.org testing main non-free

# Power Management
# deb http://repo.linrunner.de/debian sid mai

EOF
        # deb-multimedia key
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 5C808C2B65558117
        # Power Management Key
        # sudo apt-key adv --keyserver pool.sks-keyservers.net --recv-keys CD4E8809

        cd /tmp
        curl -O https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
        sudo dpkg -i deb-multimedia-keyring_2016.8.1_all.deb

}


install_yubikey() {
    # Must be Sudo
    check_is_sudo

    apt-get install -y swig libu2f-host0 libykpers-1-1 python3 python3-cryptography python3-openssl python3-pyscard python3-setuptools python3-six python3-usb pcscd python3-click --no-install-recommends

# The following NEW packages will be installed:
#  libhidapi-hidraw0 libu2f-host0 python3-asn1crypto python3-cffi-backend python3-click python3-colorama python3-cryptography python3-openssl python3-pyscard python3-usb


    # Get or update manager
    local SRC_DIR="${SOURCE_DIR}/yubikey-manager"
    if [[ ! -e "${SRC_DIR}" ]]; then
        cd "${SOURCE_DIR}"
        git clone https://github.com/Yubico/yubikey-manager.git "yubikey-manager"
        cd "${SRC_DIR}"
    else
        cd "${SRC_DIR}"
        git checkout master
        git pull
    fi
    sudo pip3 install -e .

    curl -sSL https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules > /etc/udev/rules.d/70-u2f.rules

    # echo "deb http://ppa.launchpad.net/yubico/stable/ubuntu xenial main" > /etc/apt/sources.list.d/yubico.list
    # echo "deb-src http://ppa.launchpad.net/yubico/stable/ubuntu xenial main" >> /etc/apt/sources.list.d/yubico.list
    # # add the yubico ppa gpg key
    # apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 3653E21064B19D134466702E43D5C49532CBA1A9

    # apt-get update
    # apt-get install -y \
    #         yubikey-manager \
    #         --no-install-recommends
}

# installs base packages
# the utter bare minimal shit
base() {
    fail_is_sudo
    sudo apt-get update
    sudo apt-get -y upgrade
    local base_packages=( \
          ####################################
          # Networking
          ####################################
          network-manager-gnome \
          curl \
          dnsutils \
          # Need keyring for network manager
          gnome-keyring \
          ####################################
          # App Security
          ####################################
          apparmor \
          ####################################
          # Backups
          ####################################
          duplicity \
          python-boto \
          ####################################
          # Investigation
          ####################################
          exiftool \
          strace \
          wget \
          whois \
          poppler-utils \
          lynx \
          ####################################
          # Development
          ####################################
          git \
          pylint \
          python-pip \
          python3-dev \
          python3-pip \
          python3-setuptools \
          # For dealing with builddeps problems
          #          https://ww          w.guyruten          berg.com/2          017/09/23/use-mk-build-deps-instead-of-apt-get-build-dep/
          devscripts \
          equivs \
          libssl-dev \
          ####################################
          # Writing
          ####################################
          ispell \
          uuid-runtime \
          ####################################
          # Comms Security
          ####################################
          gnupg-agent \
          gnupg2 \
          gnutls-bin \
          pinentry-curses \
          scdaemon \
          pcscd \
          libusb-1.0-0-dev \
          # pidgin \
          # pidgin-otr \
          ####################################
          # net sec
          ####################################
          macchanger \
          openvpn \
          stunnel \
          tor \
          torsocks \
          ####################################
          # General Sec
          ####################################
          # keepassxc \
          ####################################
          # Data Analysis
          ####################################
          jq \
          ####################################
          # Media
          ####################################
          libav-tools \
          # ffmpeg \
          youtube-dl \
          ####################################
          # Getting Debian to be a functional OS
          ####################################
          sudo \
          terminator \
          unzip \
          tlp \
          tlp-rdw \
          ack \
          xclip \
          bash-completion \
          # libcanberra-gtk-module \
          # libgmime-2.6-dev \
          # libncurses5-dev \
          # libtalloc-dev \
          # libxapian-dev \
          ####################################
          # File Viewing
          ####################################
          urlview \
          unzip \
          zip \
          libxml2-utils \
          #binwalk \
          # Checking on status of file transfers
          progress \
          ####################################
          # System Exploration
          ####################################
          lsof \
          silversearcher-ag \
          tree \
          # fdupes: https://www.tecmint.com/fdupes-find-and-delete-duplicate-files-in-linux/
          fdupes \
          ####################################
          # Productivity
          ####################################
          taskwarrior \
          timewarrior )

    # Swap out for Ubuntu specific packages if on ubuntu
    if $(grep -qi ubuntu /proc/version); then
        for i in "${!base_packages[@]}"; do
            if [[ ${base_packages[$i]} == "stunnel" ]]; then
                base_packages[$i]="stunnel4"
            fi
            if [[ ${base_packages[$i]} == "exiftool" ]]; then
                base_packages[$i]="libimage-exiftool-perl"
            fi
            if [[ ${base_packages[$i]} == "ack" ]]; then
                base_packages[$i]="ack-grep"
            fi
            if [[ ${base_packages[$i]} == "libav-tools" ]]; then
                base_packages[$i]="ffmpeg"
            fi
        done
    fi
    sudo apt-get install -y "${base_packages[@]}" --no-install-recommends

    # If using locally stored email and notmuch
    # apt-get install -y offlineimap --no-install-recommends
    # Else if using remote mail and mutt
    # local remote_mail=$(echo "Just Mutt and imap")

    setup_sudo
    sudo apt-get autoremove
    sudo apt-get autoclean
    sudo apt-get clean
}

install_chrome() {
    fail_is_sudo

    echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

    curl -sSL https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

    sudo apt-get update
    sudo apt-get install -y \
            google-chrome-stable \
            --no-install-recommends
}


install_signal() {
    curl -s https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
    echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
    sudo apt update && sudo apt install signal-desktop
}

# installs docker master
# and adds necessary items to boot params
install_docker() {
    fail_is_sudo

    # add docker gpg key
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    # create docker group
    sudo groupadd docker || true
    sudo gpasswd -a "$TARGET_USER" docker

    # Include contributed completions
    mkdir -p /etc/bash_completion.d
    sudo curl -sSL -o /etc/bash_completion.d/docker https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker

    # get the binary
    local tmp_tar=/tmp/docker.tgz
    local binary_uri="https://download.docker.com/linux/static/edge/x86_64"
    local docker_version
    docker_version=$(curl -sSL "https://api.github.com/repos/docker/docker-ce/releases/latest" | jq --raw-output .tag_name)
    docker_version=${docker_version#v}
    # local docker_sha256
    # docker_sha256=$(curl -sSL "${binary_uri}/docker-${docker_version}.tgz.sha256" | awk '{print $1}')
    (
        set -x
        curl -fSL "${binary_uri}/docker-${docker_version}.tgz" -o "${tmp_tar}"
        # echo "${docker_sha256} ${tmp_tar}" | sha256sum -c -
        sudo tar -C /usr/local/bin --strip-components 1 -xzvf "${tmp_tar}"
        rm "${tmp_tar}"
        docker -v
    )
    sudo chmod +x /usr/local/bin/docker*

    sudo curl -sSL -o /etc/systemd/system/docker.service https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/systemd/system/docker.service
    sudo curl -sSL -o /etc/systemd/system/docker.socket https://raw.githubusercontent.com/jessfraz/dotfiles/master/etc/systemd/system/docker.socket

    sudo systemctl daemon-reload
    sudo systemctl enable docker

    # update grub with docker configs and power-saving items
    sudo sed -i.bak 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1 pcie_aspm=force apparmor=1 security=apparmor"/g' /etc/default/grub
    echo "Docker has been installed. If you want memory management & swap you have to run update-grub & reboot."
    PS3='Would you like to do that now? '
    options=("Yes" "No")
    select opt in "${options[@]}"; do
        case $opt in
            "Yes")
                echo "Updating and Restarting"
                sudo update-grub
                sudo shutdown -r 0
                break
                ;;
            "No")
                echo "Continuing without restarting"
                break
                ;;
            *) echo "Invalid option. Please choose again.";;
        esac
    done

    # Ensure user has access to docker dir
    sudo mkdir -p /etc/docker
    sudo chgrp docker -R /etc/docker
    sudo chmod 755 /etc/docker
}


update_containerd() {
        local tmp_tar=/tmp/containerd.tar.gz
        local containerd_version
        containerd_version=$(curl -sSL "https://api.github.com/repos/containerd/containerd/releases" | jq --raw-output .[0].tag_name)
        containerd_version=${containerd_version#v}
        local binary_uri="https://github.com/containerd/containerd/releases/download/v${containerd_version}/containerd-${containerd_version}.linux-amd64.tar.gz"
        (
        set -x
        curl -fSL "$binary_uri" -o "$tmp_tar"
        tar -C /usr/local/bin --strip-components 1 -xzvf "$tmp_tar"
        rm "$tmp_tar"
        containerd -v
        )

        # enable and start containerd
        systemctl daemon-reload
        systemctl enable containerd
        systemctl start containerd
}


get_jfraz_dockerfiles() {
    JF_SRC_DIR="${SOURCE_DIR}/JF"
    download_jf_dockerfiles
    build_jfraz_dockerfiles
}



download_jf_dockerfiles() {
    if [[ ! -e "${JF_SRC_DIR}" ]]; then
        get_git_package "${JF_SRC_DIR}" https://github.com/jessfraz/dockerfiles.git
        cd "${JF_SRC_DIR}"
        git checkout master
    else
        cd "${JF_SRC_DIR}"
        git checkout master
    fi
}

build_jfraz_dockerfiles() {
    cd "${JF_SRC_DIR}"
    local repos=( \
        slack \
        libreoffice \
        skype \
        keepassxc \
        nmap \
        inkscape \
        powershell
    )

    for repo in "${repos[@]}"; do
        build_docker_container "${repo}" "${repo}"
        cd "${JF_SRC_DIR}"
    done
}

get_dockerfiles() {
    # Jess Fraz
    # echo "Skipping Jess Fraz, remove commented line to use again"
    get_jfraz_dockerfiles
    # Other
    get_other_dockerfiles
}

get_other_dockerfiles() {
    # Prep Code
    mkdir -p "$HOME/code"
    # Viper
    install_viper_docker
    # Thug
    install_thug_docker
    # Sloppy Archivist
    install_sloppy_archive_docker
    # Radare
    install_radare_docker
    # Harpoon
    install_harpoon_docker
    # Boxjs (JS based malware
    install_boxjs_docker
    # AndroidRe
    install_android_RE_docker
}

install_boxjs_docker() {
    # Boxjs (JS based malware
    cd "$HOME/code"
    local B_SRC="${HOME}/code/box-js"
    get_git_package "$B_SRC" https://github.com/CapacitorSet/box-js.git
    build_docker_container "$B_SRC/integrations/docker" box-js
}

install_sloppy_archive_docker() {
    # Sloppy Archivist
    cd "$HOME/code"
    local SA_SRC="${HOME}/code/sloppy_archivist"
    get_git_package "$SA_SRC" https://github.com/seamustuohy/sloppy_archivist.git
    build_docker_container "$SA_SRC" sloppy_archivist
}

install_radare_docker() {
    # Radare
    cd "$HOME/code"
    local R2_SRC="${HOME}/code/radare2"
    get_git_package "$R2_SRC" https://github.com/radare/radare2.git
    build_docker_container "$R2_SRC" radare2
}


install_harpoon_docker() {
    # Harpoon
    cd "$HOME/code"
    local HSRC="${HOME}/code/dockerfiles"
    # TODO upload dockerfiles
    get_git_package "$HSRC" https://github.com/seamustuohy/dockerfiles.git
    daily_rebuild_docker_container "$HSRC/harpoon" harpoon
}

install_cyobstract_docker() {
    # Harpoon
    cd "$HOME/code"
    local HSRC="${HOME}/code/dockerfiles"
    # TODO upload dockerfiles
    get_git_package "$HSRC" https://github.com/seamustuohy/dockerfiles.git
    daily_rebuild_docker_container "$HSRC/cyobstract" cyobstract
}


install_dcode() {
    # Dcode
    cd "$HOME/code"
    local HSRC="${HOME}/code/dockerfiles"
    build_docker_container "$HSRC/decode" decode
}

install_play_docker() {
    cd "$HOME/code"
    local HSRC="${HOME}/code/dockerfiles"
    # TODO upload dockerfiles
    get_git_package "$HSRC" https://github.com/seamustuohy/dockerfiles.git
    build_docker_container "$HSRC/play" play
}


install_android_RE_docker() {
    # AndroidRe
    cd "$HOME/code"
    local A_SRC="$HOME/code/androidre"
    get_git_package "$A_SRC" https://github.com/cryptax/androidre.git
    build_docker_container "${A_SRC}" androidre
    # Create base project (required)
}

install_viper_docker() {
    # Viper
    cd "$HOME/code"
    local HSRC="${HOME}/code/dockerfiles"
    # TODO upload dockerfiles
    # get_git_package "$dockerfunc" https://github.com/seamustuohy/dockerfiles.git
    build_docker_container "$HSRC/viper" viper
    # pip3 install pytest
    # sed -i 's/--cov=viper//' setup.cfg
    # rm -fr tests/web/
    # python3 -m pytest
}

# # USING THE OFFICIAL (SEE: OLD) DOCKERFILE
# install_viper_docker() {
#     # Viper
#     cd "$HOME/code"
#     local V_SRC="$HOME/code/viper"
#     get_git_package "$V_SRC" https://github.com/viper-framework/viper.git
#     get_git_package "${V_SRC}-docker" https://github.com/viper-framework/viper-docker.git
#     build_docker_container "${V_SRC}-docker" viper
#     # Create base project (required)
#     mkdir -p "${HOME}/malware"
# }

install_thug_docker() {
    cd "$HOME/code"
    local SRC="${HOME}/code/dockerfiles"
    # TODO upload dockerfiles
    get_git_package "$dockerfiles" https://github.com/seamustuohy/dockerfiles.git
    mkdir -p "${HOME}/malware/thug/logs"
    chmod a+xwr "${HOME}/malware/thug/logs"
    build_docker_container "${SRC}/thug" thug
}

# install_thug_docker() {
#     # REMnux
#     cd "$HOME/code"
#     local RMN_SRC="${HOME}/code/REMnux"
#     get_git_package "$RMN_SRC" https://github.com/REMnux/docker.git
#     # thug
#     mkdir -p "${HOME}/malware/thug/logs"
#     chmod a+xwr "${HOME}/malware/thug/logs"
#     build_docker_container "$RMN_SRC/thug" thug
# }

# install_maltools_docker() {
#     # # Malware Tools
#     cd "$HOME/code"
#     local MT_SRC="${HOME}/code/malware-tools-docker"
#     get_git_package "$MT_SRC" https://github.com/nshadov/malware-tools-docker.git
#     build_docker_container "$MT_SRC" malware-tools
# }

build_docker_container() {
    local SRC_DIR="${1}"
    local NAME="${2}"
    # Go to source directory
    local DOCKER_REPO_PREFIX="s2e"
    cd "${SRC_DIR}"
    docker build --rm --force-rm -t "${DOCKER_REPO_PREFIX}/${NAME}" .
}

daily_rebuild_docker_container() {
    # Requires the following line at the point of rebuilding
    # ARG GIT_CACHE_DATE="2018-04-10"

    local SRC_DIR="${1}"
    local NAME="${2}"
    # Go to source directory
    local DOCKER_REPO_PREFIX="s2e"
    cd "${SRC_DIR}"
    docker build --rm --force-rm \
           --build-arg GIT_CACHE_DATE=$(date +%F)\
           -t "${DOCKER_REPO_PREFIX}/${NAME}" .
}

install_virtualbox() {
        # check if we need to install libvpx1
        PKG_OK=$(dpkg-query -W --showformat='${Status}\n' libvpx1 | grep "install ok installed") || true
        echo "Checking for libvpx1: $PKG_OK"
        if [ "" == "$PKG_OK" ]; then
                echo "No libvpx1. Installing libvpx1."
                jessie_sources=/etc/apt/sources.list.d/jessie.list
                echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" > "$jessie_sources"

                apt update
                apt install -y -t jessie libvpx1 \
                        --no-install-recommends

                # cleanup the file that we used to install things from jessie
                rm "$jessie_sources"
        fi

        echo "deb http://download.virtualbox.org/virtualbox/debian stretch contrib" >> /etc/apt/sources.list.d/virtualbox.list

        curl -sSL https://www.virtualbox.org/download/oracle_vbox.asc | apt-key add -
        curl -sSL  https://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc  | apt-key add -
        curl -sSL  https://download.virtualbox.org/virtualbox/debian/sun_vbox.asc | apt-key add -
        curl -sSL  https://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc | apt-key add -

        apt update
        apt install -y \
                virtualbox-5.0 \
        --no-install-recommends
}

install_ansible() {
    local ansible_source="deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
    echo "${ansible_source}" | sudo tee -a /etc/apt/sources.list.d/ansible.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    sudo apt-get update
    sudo apt-get install ansible
}


install_algo() {
    echo "Requires Ansible"
    sudo apt-get install network-manager-strongswan
    echo "To install Profile do the following"
    echo "git clone https://github.com/trailofbits/algo.git"
    echo "cd algo"
    echo "Either create a new algo server or use existing configs"
    echo "----- new server ------"
    echo " docker run --cap-drop ALL -it -v ~/code/algo/configs:/data s2e/algo:latest"
    echo "docker cp [DOCKER CONTAINER ID]:/algo ~/code/algo/configs"
    echo "----- use existing configs ------"
    echo "cp ~/[path]/[to]/[server]/[config] ./configs"
    echo "Follow Linux Config - (https://github.com/trailofbits/algo/blob/master/docs/client-linux.md)"
    echo "It will look something like this"
    echo "ansible-playbook deploy_client.yml -e 'client_ip=localhost vpn_user=XXXXX server_ip=XXX.XXX.XXX.XXX ssh_user=NAN' --ask-become-pass"
}

install_vagrant() {
        VAGRANT_VERSION=2.0.1

        # if we are passing the version
        if [[ ! -z "$1" ]]; then
                export VAGRANT_VERSION=$1
        fi

        # check if we need to install virtualbox
        PKG_OK=$(dpkg-query -W --showformat='${Status}\n' virtualbox | grep "install ok installed")  || true
        echo "Checking for virtualbox: $PKG_OK"
        if [ "" == "$PKG_OK" ]; then
                echo "No virtualbox. Installing virtualbox."
                install_virtualbox
        fi

        tmpdir=$(mktemp -d)
        (
        cd "$tmpdir"
        curl -sSL -o vagrant.deb "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb"
        dpkg -i vagrant.deb
        )

        rm -rf "$tmpdir"

        # install plugins
        vagrant plugin install vagrant-vbguest
}



get_dotfiles() {
        # create subshell
        (
        cd "$HOME"

        # install dotfiles from repo
        git clone git@github.com:seamustuohy/dotfiles.git "${HOME}/dotfiles"
        cd "${HOME}/dotfiles"

        # installs all the things
        make

        # enable dbus for the user session
        # systemctl --user enable dbus.socket

        sudo systemctl enable "i3lock@${TARGET_USER}"
        sudo systemctl enable suspend-sedation.service

        make_home
        )
}

make_home() {
    cd "$HOME"
    mkdir -p "${HOME}/Pictures"
    mkdir -p "${HOME}/code"
    mkdir -p "${HOME}/malware"
    mkdir -p "${HOME}/temp"
    mkdir -p "${HOME}/Downloads"
    mkdir -p "${HOME}/Music"
}

get_neomutt() {
    #sudo mkdir -p /var/mail/s2e
    get_neomutt_dependencies
    NEOMUTT_SRC_DIR="${SOURCE_DIR}/neomutt"
    download_neomutt
    rebuild_neomutt_from_source
}

get_neomutt_dependencies() {
    local packages=( \
                     # Required for SMTP authentication
                     libsasl2-modules \
    )
    apt-get install -y "${packages[@]}" --no-install-recommends
}

download_neomutt() {
    if [[ ! -e "${NEOMUTT_SRC_DIR}" ]]; then
        get_git_package "${SOURCE_DIR}"/neomutt https://github.com/neomutt/neomutt
        cd "${NEOMUTT_SRC_DIR}"
        git checkout master
    else
        cd "${NEOMUTT_SRC_DIR}"
        git checkout master
        echo "Pulling latest version"
        git pull
        VERSION=$(git tag | sort -V | tail -1)
        echo "Checking out release $VERSION"
        git checkout "${VERSION}"
    fi
}

rebuild_neomutt_from_source() {
    # Don't build in source directory
    # Create tmpdir for building
    local tmpdir
    tmpdir=$(mktemp -dt "$(basename "$0").XXXXX")

    cp -fr "${NEOMUTT_SRC_DIR}" "${tmpdir}/neomutt"
    cd "${tmpdir}/neomutt"
    get_temp_dependencies "neomutt"

    #autoreconf -i
    ./configure --prefix=/usr/local \
                --enable-gpgme \
                --enable-debug \
                --sasl \
                --ssl \
                --lmdb \
                --with-ssl=/usr/lib/ssl
    make
    sudo make install

    # Delete temp source dir
    rm -fr "${tmpdir}"
    # Delete build dependencies
    remove_temp_dependencies "neomutt"
}

get_temp_dependencies() {
    local package_name="${1}"
    # TODO get working with build-deps
    sudo apt-get install -y liblmdb-dev
    sudo mk-build-deps "${1}" --install --root-cmd sudo --remove
}

remove_temp_dependencies() {
    local package_name="${1}"
    sudo apt remove -y "${1}-build-deps"
}

get_git_package() {
    local package_dir="${1}"
    local repo="${2}"
    if [[ ! -e $package_dir ]]; then
        git clone "$repo"  "$package_dir"
    else # Update to the latest version for good measure.
        git --git-dir="$package_dir"/.git --work-tree="$package_dir"  pull
    fi
}

install_emacs() {
    #I'm running testing FFS
    sudo apt install emacs25

    ## Requirements for packages
    # Helm-Dash
    sudo apt install sqlite3
    # Setup environment
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

    sudo update-alternatives --install /usr/bin/editor editor "$(which emacs)" 60
    sudo update-alternatives --config editor
}

install_vim() {

    # NeoVim w/ QT
    sudo apt-get install -y \
         neovim-qt \
         --no-install-recommends
    # Python (:python) support via Debian unstable.
    pip3 install -U \
         neovim

    # update alternatives to neovim
    sudo update-alternatives --install /usr/bin/vi vi "$(which nvim)" 60
    sudo update-alternatives --config vi
    sudo update-alternatives --install /usr/bin/vim vim "$(which nvim)" 60
    sudo update-alternatives --config vim
}

setup_vim() {
    # Set XDG Configuration Directory
    local XDG_CONFIG_HOME="${HOME}/.config"
    # Package Directory
    local VIM_PKG_DIR="${HOME}/.vim/bundle"
    # Sets up symlink for user and root .vimrc for vim and neovim
    ln -snf "${HOME}/.vim" "${XDG_CONFIG_HOME}/nvim"
    ln -snf "${HOME}/.vimrc" "${XDG_CONFIG_HOME}/nvim/init.vim"

    # Setup Colors
    # mkdir -p ~/.vim/colors/
    # cp "${VIM_PKG_DIR}/vim-colors-solarized/colors/solarized.vim" ~/.vim/colors/solarized.vim
}

install_vim_plugins() {
    mkdir -p ~/.vim/bundle
    local VIM_PKG_DIR="${HOME}/.vim/bundle"
    get_git_package \
        "${VIM_PKG_DIR}/vim-better-whitespace" \
        https://github.com/ntpeters/vim-better-whitespace.git
    get_git_package \
        "${VIM_PKG_DIR}/vim-airline" \
        https://github.com/vim-airline/vim-airline.git
    get_git_package \
        "${VIM_PKG_DIR}/vim-airline-themes" \
        https://github.com/vim-airline/vim-airline-themes
    get_git_package \
        "${VIM_PKG_DIR}/vim-colors-solarized" \
        https://github.com/altercation/vim-colors-solarized.git

    # Setup Pathogen
    rm -fr /tmp/pathogen
    get_git_package \
        "/tmp/pathogen" \
        https://github.com/tpope/vim-pathogen.git

    mkdir -p ~/.vim/autoload/
    cp /tmp/pathogen/autoload/pathogen.vim ~/.vim/autoload/pathogen.vim

}


# install_emacs() {
#         # create subshell
#     (
#         cd "$HOME"
#         # Install dependencies
#         local emacs_deps=( \
#             # Build tools
#             autoconf \
#             automake \
#             libtool \
#             build-essential \
#             libncurses5-dev \
#             # Documentation
#             texinfo  \
#             # X windows
#             xorg-dev \
#             libgtk2.0-dev \
#             # Viewing files
#             libgif-dev \
#             libtiff-dev \
#             libpng-dev \
#             libjpeg-dev \
#             librsvg2-dev \
#             libotf-dev \
#             libxml2-dev \
#             # Networking, and sys integration
#             libdbus-1-dev \
#             libgnutls28-dev  \
#             # Internationalization
#             libm17n-dev )

#         sudo apt-get install -y "${emacs_deps[@]}" --no-install-recommends

#         local EMACS_SRC_DIR="${SOURCE_DIR}/emacs"
#         if [[ ! -e "${EMACS_SRC_DIR}" ]]; then
#             cd "${SOURCE_DIR}"
#             sudo git clone git://git.sv.gnu.org/emacs.git "emacs"
#         else
#             cd "${EMACS_SRC_DIR}"
#             git checkout master
#             git pull
#         fi

#         # Don't build in source directory
#         # Create tmpdir for building
#         local tmpdir
#         tmpdir=$(mktemp -dt "$(basename "$0").XXXXX")
#         tmpdir="${tmpdir}/emacs"
#         cp -fr  "${EMACS_SRC_DIR}" "${tmpdir}"
#         cd "${tmpdir}"

#         # Get latest release
#         local last_tag
#         last_tag=$(git describe --tags)
#         git checkout "${last_tag}"

#         # Install Emacs
#         cd emacs
#         ./autogen.sh
#         ./configure --with--m17n-flt
#         make bootstrap
#         sudo make install

#         # Delete temp source dir
#         rm -fr "${tmpdir}"

#         # Setup environment
#         # Create emacs config dir
#         mkdir -p "${HOME}/.emacs.d"

#         # Add snippets
#         local SNIPPET_DIR
#         SNIPPET_DIR="${HOME}/.emacs.d/snippets"
#         if [[ ! -e "${SNIPPET_DIR}" ]]; then
#             ln -snf "${HOME}/dotfiles/snippets" "${SNIPPET_DIR}"
#         fi
#     )
# }

# install graphics drivers
install_graphics() {
        local system=$1

        if [[ -z "$system" ]]; then
            echo "You need to specify whether it's intel, geforce or optimus"
            echo "Here is a hint: "
            lspci | grep -i graphic
            exit 1
        fi

        local pkgs=( xorg xserver-xorg )

        case $system in
                "intel")
                        pkgs+=( xserver-xorg-video-intel )
                        ;;
                "geforce")
                        pkgs+=( nvidia-driver )
                        ;;
                "optimus")
                        pkgs+=( nvidia-kernel-dkms bumblebee-nvidia primus )
                        ;;
                *)
                        echo "You need to specify whether it's intel, geforce or optimus"
                        exit 1
                        ;;
        esac

        apt install -y "${pkgs[@]}" --no-install-recommends
}

# install wifi drivers
install_wifi() {
        local system=$1

        if [[ -z "$system" ]]; then
            echo "You need to specify whether it's broadcom or intel"
            echo "Here is a hint: "
            lspci | grep -i wireless
            exit 1
        fi

        if [[ $system == "broadcom" ]]; then
                local pkg="broadcom-sta-dkms"

                apt install -y "$pkg" --no-install-recommends
        else
                update-iwlwifi
        fi
}

install_wmapps() {
    echo "installing i3 extras"
    # Install apt based packages
    local aptpkgs=( \
        # X Window Manager
        xcompmgr \
        ####################################
        # i3
        ####################################
        i3 \
        i3lock \
        i3status \
        suckless-tools \
        ####################################
        # Background
        ####################################
        feh \
        ####################################
        # Basic File Manager
        ####################################
        nautilus \
        # nautilus needs eject to eject USB's
        eject \
        ####################################
        # Sound
        ####################################
        pulseaudio \
        pavucontrol \
        blueman \
        ####################################
        # Controlling backlight levels
        # Xbacklight does not work correctly on many machines
        # So, I "DO IT LIVE"
        # NOTE: Now this is replaced by a script
        ####################################
        # echo "800" |sudo tee  /sys/class/backlight/intel_backlight/brightness
        # echo "100" |sudo tee  /sys/class/backlight/intel_backlight/brightness
        # xbacklight \
        ####################################
        # Screenshots with scrot
        ####################################
        scrot )
    apt-get install -y "${aptpkgs[@]}" --no-install-recommends

    # Install pip i3 packages
    # You need to install them one at a time
    sudo -H pip install -U wheel
    sudo -H pip install -U i3-py
    sudo -H pip install -U quickswitch-i3
    sudo -H pip install -U py3status
    # i3Bar VPN script
    sudo -H pip install -U pydbus
    sudo -H pip install -U pytz
    sudo -H pip install -U tzlocal
    sudo -H pip install -U PyOrgMode
}


setup_sudo() {
        # add user to sudoers
        sudo adduser "$TARGET_USER" sudo

        # add user to systemd groups
        # then you wont need sudo to view logs and shit
        sudo gpasswd -a "$TARGET_USER" systemd-journal
        sudo gpasswd -a "$TARGET_USER" systemd-network
}

usage() {
        echo -e "install.sh\n\tThis script installs my basic setup for a debian laptop\n"
        echo "Usage:"
        echo "  sources                     - setup sources & install base pkgs"
        echo "  wifi {broadcom,intel}       - install wifi drivers"
        echo "  graphics {dell,mac,lenovo}  - install graphics drivers"
        echo "  wm                          - install window manager/desktop pkgs"
        echo "  dotfiles                    - get dotfiles"
        echo "  emacs                       - get emacs"
        echo "  home                        - build home dir"
        echo "  dockerfile                  - get & build JF's dockerfiles"
        echo "  scripts                     - install scripts"
        echo "  vagrant                     - install vagrant and virtualbox"
        echo "  todo                        - check missing items from base"
}

get_TODO() {
    # Remove Debugging if on
    # TODO remove DEBUGGING
    set +x

    ## EMACS
    check_command_installed emacs
    ## I3
    check_command_installed i3
    ## Mutt
    check_command_installed mutt
    ## virtualbox
    check_command_installed virtualbox
    ## vagrant
    check_command_installed vagrant

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

graphics_selector() {
       PS3="Which Graphics Card do you have? (intel, geforce or optimus)"
       options=("intel" "geforce" "optimus" "skip" "help")
       select opt in "${options[@]}"; do
           case $opt in
               "intel")
                   install_graphics "intel"
                   break
                   ;;
               "geforce")
                   install_graphics "geforce"
                   break
                   ;;
               "optimus")
                   install_graphics "optimus"
                   break
                   ;;
               "skip")
                   break
                   ;;
               "help")
                   echo "Here is a hint: "
                   lspci | grep -i graphic
                   ;;
               *)
                   echo "Not Valid, Here is a hint: "
                  lspci | grep -i graphic
                  ;;
           esac
       done
}

wifi_selector() {
       PS3="Which Wifi card do you have?"
       options=("intel" "broadcom" "skip" "help")
       select opt in "${options[@]}"; do
           case $opt in
               "intel")
                   install_wifi "intel"
                   break
                   ;;
               "broadcom")
                   install_wifi "broadcom"
                   break
                   ;;
               "skip")
                   break
                   ;;
               "help")
                   echo "Here is a hint: "
                   lspci | grep -i wire
                   ;;
               *) echo "Not valid; Here is a hint: "
                  lspci | grep -i wire
                  ;;
           esac
       done
}


enable_namespaces() {
    suso sysctl -w kernel.unprivileged_userns_clone=1
}

install_veracrypt() {
    local VERSION=1.21
curl https://www.idrix.fr/VeraCrypt/VeraCrypt_PGP_public_key.asc | gpg --import
wget https://launchpad.net/veracrypt/trunk/"${VERSION}"/+download/veracrypt-"${VERSION}"-setup.tar.bz2
wget https://launchpad.net/veracrypt/trunk/"${VERSION}"/+download/veracrypt-"${VERSION}"-setup.tar.bz2.sig
gpg --verify veracrypt-"${VERSION}"-setup.tar.bz2.sig
printf "ID=0x54DDD393, Fingerprint=993B7D7E8E413809828F0F29EB559C7C54DDD393\n\n\n"
printf "OK?"
read
printf "\n\n"
tar -xvf veracrypt-"${VERSION}"-setup.tar.bz2
printf "\n\nInstall to /tmp (option 2)!\n\nOK?"
read
./veracrypt-"${VERSION}"-setup-gui-x64
mkdir veracrypt_installed
tar -xvf /tmp/veracrypt_"${VERSION}"_amd64.tar.gz -C veracrypt_installed
sudo cp -R veracrypt_installed/usr/bin/* /usr/local/bin/
sudo cp -R veracrypt_installed/usr/share/* /usr/local/share/
}



first_boot() {
    fail_is_sudo
    get_user
    # check_is_sudo
    enable_namespaces
    setup_sources
    base
    install_docker
}

first_user_boot() {
    get_user
    check_is_sudo
    graphics_selector
    wifi_selector
    install_wmapps
    get_neomutt
    install_emacs
    install_vim
    install_chrome
    install_signal
    install_yubikey
}


# Choose a user account to use for this installation
main() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi

    if [[ $cmd == "sources" ]]; then
        get_user
        fail_is_sudo
        setup_sources
    elif [[ $cmd == "base" ]]; then
        fail_is_sudo
        get_user
        base
    elif [[ $cmd == "firstboot" ]]; then
        first_boot
    elif [[ $cmd == "firstuser" ]]; then
        first_user_boot
    elif [[ $cmd == "kernel" ]]; then
        check_is_sudo
        enble_namespaces
    elif [[ $cmd == "wifi" ]]; then
        check_is_sudo
        wifi_selector
    elif [[ $cmd == "docker" ]]; then
        get_user
        install_docker
    elif [[ $cmd == "containerd" ]]; then
        check_is_sudo
        get_user
        update_containerd
    elif [[ $cmd == "graphics" ]]; then
        check_is_sudo
        graphics_selector
    elif [[ $cmd == "wm" ]]; then
        check_is_sudo
        install_wmapps
    elif [[ $cmd == "dotfiles" ]]; then
        get_user
        get_dotfiles
    elif [[ $cmd == "emacs" ]]; then
        # check_is_sudo
        install_emacs
    elif [[ $cmd == "mutt" ]]; then
        check_is_sudo
        get_neomutt
        printf "Get the public key if the public key isn't already in your keychain"
        printf "If you have not done it already put your card in now"
        printf "run these commands once card edit opens"
        printf "fetch"
        printf "quit"
        # read
        gpg2 --card-edit
    elif [[ $cmd == "home" ]]; then
        make_home
    elif [[ $cmd == "scripts" ]]; then
        install_scripts
    elif [[ $cmd == "veracrypt" ]]; then
        install_veracrypt
    elif [[ $cmd == "ansible" ]]; then
        install_ansible
    elif [[ $cmd == "vagrant" ]]; then
        check_is_sudo
        install_vagrant "$2"
    elif [[ $cmd == "dockerfiles" ]]; then
        get_dockerfiles
    elif [[ $cmd == "viperdocker" ]]; then
        install_viper_docker
    elif [[ $cmd == "jfrazdocker" ]]; then
        get_jfraz_dockerfiles
#    elif [[ $cmd == "maltoolsdocker" ]]; then
        #        install_maltools_docker
    elif [[ $cmd == "decodedocker" ]]; then
        install_dcode
    elif [[ $cmd == "harpoon" ]]; then
        install_harpoon_docker
    elif [[ $cmd == "browser" ]]; then
        check_is_sudo
        install_chrome
    elif [[ $cmd == "thug" ]]; then
        install_thug_docker
    elif [[ $cmd == "signal" ]]; then
        get_user
        install_signal
    elif [[ $cmd == "yubikey" ]]; then
        check_is_sudo
        install_yubikey
    elif [[ $cmd == "virtualbox" ]]; then
        check_is_sudo
        install_virtualbox
    elif [[ $cmd == "cyobstract" ]]; then
        #check_is_sudo
        install_cyobstract_docker
    elif [[ $cmd == "vim" ]]; then
        install_vim
        install_vim_plugins
        setup_vim
    elif [[ $cmd == "todo" ]]; then
        get_TODO
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
