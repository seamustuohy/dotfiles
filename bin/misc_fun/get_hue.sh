#!/usr/bin/env bash
#
# This file is part of package name, a package description short.
# Copyright © 2019 seamus tuohy, <code@seamustuohy.com>
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


function main() {
    filename="${1}"
    # Turned alpha off to ensure only RGB is returned instead of RGBA
    RGBS=$(convert "${filename}" -colors 16 -depth 8 -format "%c" -alpha off histogram:info: 2>@1)
    while IFS=$'\n' read -ra ADDR; do
        for i in "${ADDR[@]}"; do
            #echo $i
            rgb=$(echo $i| awk -F"[()]" '{print $2}')
            #echo $(echo "$rgb" | sed 's/,/ /g' )
            IFS=' '; read -r R G B <<<$(echo "$rgb" | sed 's/,/ /g' )
            R_perc=$(echo "$R/255" | bc -l)
            G_perc=$(echo "$G/255" | bc -l)
            B_perc=$(echo "$B/255" | bc -l)
            # Find the minimum and maximum values of R, G and B.
            MAX=$(printf "$R_perc\n$G_perc\n$B_perc" | sort | tail -n 1)
            MIN=$(printf "$R_perc\n$G_perc\n$B_perc" | sort | head -n 1)
            # If the min and max value are the same, it means that there is no saturation.
            if [[ $(bc -l <<< "$MIN == $MAX") -eq 1 ]]; then
                SATURATION=0
                HUE=0
            fi
            # Calculate Saturation
            lum=$(echo "(($R+$R+$B+$G+$G+$G)/6)/255" | bc -l)
            if [[ $(bc -l <<< "0.5 > $lum") -eq 1 ]]; then
               # If Luminance is smaller then 0.5, then Saturation = (max-min)/(max+min)
                SATURATION=$(echo "($MIN-$MAX)/($MAX+$MIN)" | bc -l)
                # echo $SATURATION
            else
                # If Luminance is bigger then 0.5. then Saturation = ( max-min)/(2.0-max-min)
                SATURATION=$(echo "($MAX-$MIN)/(2.0-$MAX-$MIN)" | bc -l)
                # echo $SATURATION
            fi
            # Get Hue
            if [[ $(bc -l <<< "$R_perc == $MAX") -eq 1 ]]; then
                # If Red is max, then Hue = (G-B)/(max-min)
                HUE=$(echo "($G_perc-$B_perc)/($MAX-$MIN)" | bc -l)
                Hue_appearance="red"
                # echo $HUE
                # echo $Hue_appearance
            elif [[ $(bc -l <<< "$G_perc == $MAX") -eq 1 ]]; then
                # If Green is max, then Hue = 2.0 + (B-R)/(max-min)
                HUE=$(echo "2.0 + ($B_perc-$R_perc)/($MAX-$MIN)" | bc -l)
                Hue_appearance="green"
                # echo $HUE
                # echo $Hue_appearance
            elif [[ $(bc -l <<< "$B_perc == $MAX") -eq 1 ]];  then
                # If Blue is max, then Hue = 4.0 + (R-G)/(max-min)
                HUE=$(echo "4.0 + ($R_perc-$G_perc)/($MAX-$MIN)" | bc -l)
                Hue_appearance="blue"
                # echo $HUE
                # echo $Hue_appearance
            fi
            hex=$(echo $i | cut -d '#' -f 2 | cut -d ' ' -f 1)
            #echo $rgb
            #echo $hex
            # echo $lum
            # echo  -e "\e[48;5;$(fromhex $hex)m$R,$G,$B - $Hue_appearance - HUE $HUE - SAT $SATURATION - LUM $lum \e[0m"
            if ( [[ $(bc -l <<< "0.55 < $lum") -eq 1 ]] \
                     && [[ $(bc -l <<< "0.5 < $HUE") -eq 1 ]] ); then
                # echo "here"
                # echo  -e "\e[48;5;$(fromhex $hex)m$Hue_appearance \e[0m"
                # echo  -e "\e[48;5;$(fromhex $hex)m$R,$G,$B - $Hue_appearance - $hex - HUE $HUE - SAT $SATURATION - LUM $lum \e[0m"
                echo  -e "\e[48;5;$(fromhex $hex)m$HUE $hex \e[0m"
                #echo $hex
            fi
            done
    done <<< "$RGBS"
}

function fromhex() {
  hex=$1
  if [[ $hex == "#"* ]]; then
    hex=$(echo $1 | awk '{print substr($0,2)}')
  fi
  r=$(printf '0x%0.2s' "$hex")
  g=$(printf '0x%0.2s' ${hex#??})
  b=$(printf '0x%0.2s' ${hex#????})
  echo -e `printf "%03d" "$(((r<75?0:(r-35)/40)*6*6+(g<75?0:(g-35)/40)*6+(b<75?0:(b-35)/40)+16))"`
}


cleanup() {
    # put cleanup needs here
    exit 0
}

trap 'cleanup' EXIT


main "${1}"
