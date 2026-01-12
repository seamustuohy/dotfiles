#!/bin/bash
ID=`xdotool getwindowfocus`
QUBE=`xprop _QUBES_VMNAME -id $ID|cut -f2 -d\" `
if [[ "$QUBE" == "_QUBES_VMNAME:  not found." ]]; then
  exit
else
    CURRENTTIME=`date +"%Y-%m-%d_%T"`
    SCREENSHOT="/home/$USER/Pictures/screenshot_${CURRENTTIME}.png"
    xfce4-screenshooter -w -s $SCREENSHOT
    # Move the screenshot into the defined Qube. Should be in QubesIncoming on that Qube.
    qvm-move-to-vm $QUBE $SCREENSHOT
    rm -f $SCREENSHOT
fi
