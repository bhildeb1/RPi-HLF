#!/bin/bash

# (1) load tun & tap kernel modules:
#sudo modprobe tun tap

# (2) create network bridge:
#sudo ip link add br0 type bridge

# (3) create virtual network devices (vNIC):
sudo ip tuntap add dev tap0 mode tap
#sudo ip tuntap add dev tap1 mode tap

# (4) set bridge & NIC as down:
#sudo ifconfig br0 down
#sudo ifconfig eno1 down
#sudo ip link set dev br0 down
#sudo ip link set dev eno1 down

# (5) connect bridge to physical network device (NIC):
sudo ip link set dev eno1 master br0

# (5) connect bridge to vNIC(s):
sudo ip link set dev tap0 master br0
#sudo ip link set dev tap1 master br0

# (7) remove ip address from NIC:
#sudo ip address delete 192.168.1.148/24 dev eno1

# (8) assign removed ip to bridge:
sudo ip address add 192.168.0.1/24 dev br0
#sudo ip address add 192.168.1.148/24 dev br0

# (9) set bridge status to up:
#sudo ip link set dev br0 up

# (10) set vNIC (tap) status to up:
sudo ip link set dev tap0 up

# (11) set NIC status to up:
#sudo ip link set dev eno1 up

# (12) tell host machine to use br0 in lieu of eno1
#sudo ip route add default via 192.168.1.148 dev br0
#sudo ip route add default via 192.168.0.1 dev br0

# (13) allow DNS queries thru bridge
#sudo resolvectl dns br0 192.168.1.148

# (14) add dns servers to bridge:
sudo nmcli con mod br0 ipv4.dns "8.8.8.8 8.8.4.4"

# (15) configure iptables to enable traffic over the bridge
sudo iptables -F FORWARD
sudo iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
