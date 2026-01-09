#!/bin/bash

sudo ip link delete dev tap0
sudo ip link delete dev br0

echo "Removed virtual network device (tap) and network bridge."
echo "Host system should revert to normal operation after a few minutes."

