#!/bin/bash

# http://billauer.co.il/blog/2013/02/usb-reset-ehci-uhci-linux/
# http://www.ubuntubuzz.com/2016/06/reset-usb-20-ehci-usb-30-xhci-without-reboot-linux.html
#

SYSEHCI=/sys/bus/pci/drivers/ehci_hcd
SYSUHCI=/sys/bus/pci/drivers/uhci_hcd

if [[ $EUID != 0 ]] ; then
 echo This must be run as root!
 exit 1
fi

if ! cd $SYSUHCI ; then
 echo Weird error. Failed to change directory to $SYSUHCI
 exit 1
fi

for i in ????:??:??.? ; do
 echo -n "$i" > unbind
 echo -n "$i" > bind
done

if ! cd $SYSEHCI ; then
 echo Weird error. Failed to change directory to $SYSEHCI
 exit 1
fi

for i in ????:??:??.? ; do
 echo -n "$i" > unbind
 echo -n "$i" > bind
done
