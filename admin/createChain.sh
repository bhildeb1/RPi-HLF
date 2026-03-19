#!/bin/bash

# helper functions

function output_heading {
     echo
     echo "-----------------------------------------------------------------------------------"
     echo
     echo "$1"
     echo
     echo "-----------------------------------------------------------------------------------"
     echo
}

function pause {
     echo
     read -p "Press ENTER to continue or X to exit: " choice
     choice="${choice^^}" # convert to uppercase
     echo

     if [ "$choice" = "X" ]; then
          echo "Exiting script ..."
          echo
          exit
     fi
}

# multi-line comment:
#if false; then
# ...
#fi

# (1) stopping & disabling fabric-ca & fabric-orderer services
output_heading "(1) Stopping fabric-ca & fabric-orderer services"
sudo systemctl stop fabric-ca.service
#sudo systemctl disable fabric-ca.service
sudo systemctl stop fabric-orderer.service
#sudo systemctl disable fabric-orderer.service

# (2) remove existing config files
output_heading "(2) Removing existing config files:"
sudo rm -rv /var/hyperledger/production
sudo rm -rv /etc/hyperledger/configtx/*
sudo rm -rv /etc/hyperledger/msp/orderer/*
sudo rm -rv /etc/hyperledger/msp/peerOrg1/*
sudo rm -rv /etc/hyperledger/msp/users/*
sudo rm -rv ./config
sudo rm -rv ./crypto-config
mkdir ./config
pause

## (3) create crypto-config folder & its contents based on crypto-config.yaml
# creates ~/fabric/crypto-config folder & its contents
output_heading "(3) Creating crypto-config folder & its contents based on crypto-config.yaml"
cryptogen generate --config=./crypto-config.yaml
pause

## (4) copy crypto-config files to their respective /etc/hyperledger/msp folders
output_heading "(4) Copying generated crypto-config files to their respective /etc/hyperledger/msp folders"
sudo cp -r ./crypto-config/ordererOrganizations/kalima.com/orderers/orderer.kalima.com/* /etc/hyperledger/msp/orderer/ 
sudo cp -r ./crypto-config/peerOrganizations/org1.kalima.com/peers/peer0.org1.kalima.com/* /etc/hyperledger/msp/peerOrg1/
sudo cp -r ./crypto-config/peerOrganizations/org1.kalima.com/users/* /etc/hyperledger/msp/users
pause

## (5) generate genesis block
# creates ~/fabric/config/genesis.block
output_heading "(5) Generating Genesis Block"
configtxgen \
     -profile OneOrgOrdererGenesis \
     -outputBlock ./genesis.block \
     -channelID sys-channel
pause

## (6) generate channel configuration transaction
# creates ~/fabric/config/aether.tx
output_heading "(6) Generating Channel Configuration"
configtxgen \
     -profile OneOrgChannel \
     -outputCreateChannelTx \
     ./aether.tx \
     -channelID aether
pause

## (7) generate anchor peer transaction
## creates ~/fabric/config/Org1MSPanchors.tx
#output_heading "(7) Generating anchor peer transaction"
#configtxgen -asOrg Org1MSP -channelID aether -profile OneOrgChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx
#pause

## (8) copy generated config files to HLF folder
# copy genesis.block, aether.tx, Org1MSPanchors.tx from ~/fabric/config/ to /etc/hyperledger/configtx/
output_heading "(8) Copying generated config files to HLF folder"
sudo cp -v genesis.block aether.tx /etc/hyperledger/configtx/
sudo cp -v crypto-config.yaml configtx.yaml orderer.yaml core.yaml /etc/hyperledger/fabric/
pause

# (9) copy channel to peer
# copy /etc/hyperledger/configtx/aether.tx (admin) to /etc/hyperledger/configtx/ (peer)
# NOTE: may need to change permissions for peer /etc/hyperledger folder to copy directly to it
output_heading "(9) Copying channel to peer"
sudo scp /etc/hyperledger/configtx/aether.tx fabric@192.168.1.9:/etc/hyperledger/configtx/
pause

# (10) copy config, crypto-config & certs to peer
# copy msp & tls directories from ~/fabric/crypto-config/peerOrganizations/org1.kalima.com/peers/peer0.org1.kalima.com/* (admin) to /etc/hyperledger/msp/peerOrg1/ (peer)
output_heading "(10) Copying config & crypto-config to peer"
sudo rsync -r ./crypto-config/peerOrganizations/org1.kalima.com/peers/peer0.org1.kalima.com/* fabric@192.168.1.9:/etc/hyperledger/msp/peerOrg1/
pause

# copy Admin@org1.kalima.com & User1@org1.kalima.com directories from ~/fabric/crypto-config/peerOrganizations/org1.kalima.com/users/ (admin) to /etc/hyperledger/msp/users/ (peer)
##sudo chown -R fabric crypto-config/peerOrganizations/org1.kalima.com/users/
sudo rsync -r ./crypto-config/peerOrganizations/org1.kalima.com/users/ fabric@192.168.1.9:/etc/hyperledger/msp/users
pause

# copy /etc/hyperledger/fabric/msp directory (admin) to /etc/hyperledger/fabric/ (peer) 
# NOTE may need to make these directories on peer for this to work
sudo rsync -r /etc/hyperledger/fabric/msp/ fabric@192.168.1.9:/etc/hyperledger/fabric/msp
pause

# (11) copy configtx.yaml, core.yaml & orderer.yaml config to peer
output_heading "(11) Copying configtx.yaml, core.yaml & orderer.yaml to peer"
sudo scp /etc/hyperledger/fabric/configtx.yaml /etc/hyperledger/fabric/core.yaml /etc/hyperledger/fabric/orderer.yaml fabric@192.168.1.9:/etc/hyperledger/fabric/
pause

# (12) enabling & starting fabric-ca & fabric-orderer services
output_heading "(3) Starting fabric-ca & fabric-orderer services"
#sudo systemctl enable fabric-ca.service
sudo systemctl start fabric-ca.service
#sudo systemctl enable fabric-orderer.service
sudo systemctl start fabric-orderer.service

# (13) restart admin node
output_heading "(14) Restarting admin node"
sudo shutdown -r now

