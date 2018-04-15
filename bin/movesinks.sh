#!/bin/bash


echo "Setting default sink to: $1";
pacmd set-default-sink $1
pacmd list-sink-inputs | grep index | while read line
do
echo "Moving input: ";
echo $line | cut -f2 -d' ';
echo "to sink: $1";
pacmd move-sink-input `echo $line | cut -f2 -d' '` $1
done


# alsa_output.pci-0000_00_1b.0.analog-stereo
# 8 Series HD Audio Controller
# Internal Laptop Audio Jack or Speakers
# Does not work on dock


# alsa_output.usb-Logitech_Logitech_USB_Headset-00-Headset.analog-stereo
# Clear Chat Comfort USB Headset

# alsa_output.pci-0000_00_03.0.hdmi-stereo-extra1
