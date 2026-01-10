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
sudo cp -r ./crypto-config/ordererOrganizations/car.com/orderers/orderer.car.com/* /etc/hyperledger/msp/orderer/ 
sudo cp -r ./crypto-config/peerOrganizations/org1.car.com/peers/peer0.org1.car.com/* /etc/hyperledger/msp/peerOrg1/
sudo cp -r ./crypto-config/peerOrganizations/org1.car.com/users/* /etc/hyperledger/msp/users
pause


## (5) generate genesis block
# creates ~/fabric/config/genesis.block
output_heading "(5) Generating Genesis Block"
configtxgen -profile OneOrgOrdererGenesis -outputBlock ./config/genesis.block -channelID sys-channel &> createchain-generate-genesis-block.log
echo "see createchain-generate-genesis-block.log for output"
cat ./createchain-generate-genesis-block.log
pause

## (6) generate channel configuration transaction
# creates ~/fabric/config/carsales.tx
output_heading "(6) Generating Channel Configuration"
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./config/carsales.tx -channelID carsales &> createchain-generate-channel-config.log
echo "see createchain-genereate-channel-config.log for output"
cat ./createchain-generate-channel-config.log
pause

## (7) generate anchor peer transaction
## creates ~/fabric/config/Org1MSPanchors.tx
#output_heading "(7) Generating anchor peer transaction"
#configtxgen -asOrg Org1MSP -channelID carsales -profile OneOrgChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx
#pause

## (8) copy generated config files to HLF folder
# copy genesis.block, carsales.tx, Org1MSPanchors.tx from ~/fabric/config/ to /etc/hyperledger/configtx/
output_heading "(8) Copying generated config files to HLF folder"
sudo chown -R fabric ./config
sudo cp -v ./config/* /etc/hyperledger/configtx/
sudo cp -v ./crypto-config.yaml /etc/hyperledger/fabric/
sudo cp -v ./configtx.yaml /etc/hyperledger/fabric/
sudo cp -v ./orderer.yaml /etc/hyperledger/fabric/
sudo cp -v ./core.yaml /etc/hyperledger/fabric/
pause

# (9) copy channel to peer
# copy /etc/hyperledger/configtx/carsales.tx (admin) to /etc/hyperledger/configtx/ (peer)
output_heading "(9) Copying channel to peer"
sudo scp /etc/hyperledger/configtx/carsales.tx fabric@192.168.0.9:/etc/hyperledger/configtx/
##sudo scp ./config/fabcar.tx fabric@192.168.0.9:/etc/hyperledger/configtx/
pause

# (10) copy config, crypto-config & certs to peer
# copy msp & tls directories from ~/fabric/crypto-config/peerOrganizations/org1.car.com/peers/peer0.org1.car.com/* (admin) to /etc/hyperledger/msp/peerOrg1/ (peer)
output_heading "(10) Copying config & crypto-config to peer"
sudo rsync -r ./crypto-config/peerOrganizations/org1.car.com/peers/peer0.org1.car.com/* fabric@192.168.0.9:/etc/hyperledger/msp/peerOrg1/

# copy Admin@org1.car.com & User1@org1.car.com directories from ~/fabric/crypto-config/peerOrganizations/org1.car.com/users/ (admin) to /etc/hyperledger/msp/users/ (peer)
##sudo chown -R fabric crypto-config/peerOrganizations/org1.car.com/users/
sudo rsync -r ./crypto-config/peerOrganizations/org1.car.com/users/ fabric@192.168.0.9:/etc/hyperledger/msp/users

# copy /etc/hyperledger/fabric/msp directory (admin) to /etc/hyperledger/fabric/ (peer) 
sudo rsync -r /etc/hyperledger/fabric/msp/ fabric@192.168.0.9:/etc/hyperledger/fabric/msp
##sudo scp -r /etc/hyperledger/fabric/msp fabric@192.168.0.9:/etc/hyperledger/fabric/
#pause

# (11) copy configtx.yaml, core.yaml & orderer.yaml config to peer
output_heading "(11) Copying configtx.yaml, core.yaml & orderer.yaml to peer"
# copy configtx.yaml, core.yaml & orderer.yaml from /etc/hyperledger/fabric/ from admin to host (same directories)
sudo scp /etc/hyperledger/fabric/configtx.yaml /etc/hyperledger/fabric/core.yaml /etc/hyperledger/fabric/orderer.yaml fabric@192.168.0.9:/etc/hyperledger/fabric/
sudo scp /etc/hyperledger/fabric-ca-server/fabric-ca-server-config.yaml /etc/hyperledger/fabric-ca-server/ca-cert.pem fabric@192.168.0.9:/home/fabric/fabric/
pause

## (12) copy crypto-config folder to peer
#output_heading "(12) Copying crypto-config folder to peer"
#sudo scp -r ./crypto-config fabric@192.168.0.9:/home/fabric/fabric/
#sudo scp -r ./crypto-config fabric@192.168.0.9:/etc/hyperledger/fabric/
#pause


# (13) enabling & starting fabric-ca & fabric-orderer services
output_heading "(3) Starting fabric-ca & fabric-orderer services"
#sudo systemctl enable fabric-ca.service
sudo systemctl start fabric-ca.service
#sudo systemctl enable fabric-orderer.service
sudo systemctl start fabric-orderer.service

# (14) restart admin node
output_heading "(14) Restarting admin node"
sudo shutdown -r now









