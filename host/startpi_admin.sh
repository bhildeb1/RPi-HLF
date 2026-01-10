#!/bin/bash

echo "Starting RPi admin"

qemu-system-aarch64 \
     -machine raspi3b \
     -cpu cortex-a53 \
     -smp 4 \
     -m 1G \
     -kernel kernel8-admin.img \
     -dtb bcm2710-rpi-3-b.dtb \
     -sd RPi-admin.img \
     -append "root=/dev/mmcblk0p2 rw rootwait rootfstype=ext4" \
     -usb -device usb-tablet -device usb-kbd \
     -display default,show-cursor=on \
     -netdev bridge,id=net0,br=br0 \
     -device usb-net,netdev=net0,mac=e6:c8:ff:09:76:9c

echo "RPi admin stopped"

