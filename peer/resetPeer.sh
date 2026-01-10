#!/bin/bash

sudo systemctl stop fabric-peer0-org1.service
#sudo systemctl disable fabric-peer0-org1.service

# delete channel artifacts
sudo rm /etc/hyperledger/configtx/*

# delete crypto materials
sudo rm -r /etc/hyperledger/msp/peerOrg1/
sudo rm -r /etc/hyperledger/msp/users/

# delete orderer config files & msp folder
sudo rm -r /etc/hyperledger/fabric/*

# delete old production chain data
sudo rm -r /var/hyperledger/production

# restart pi
sudo shutdown -r now





