#!/bin/bash

name="RPi admin node"
ip="192.168.0.8"
net_device="eth0"
is_usb0="$(ifconfig | grep usb0)"

if [[ $is_usb0 ]]; then
	net_device="usb0"
fi

echo "assigning IP $ip to $name on interface $net_device"

sudo ip addr add $ip/24 dev $net_device
sudo ip link set $net_device up

ifconfig $net_device


