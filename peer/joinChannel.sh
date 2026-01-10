#!/bin/bash

#sudo systemctl enable fabric-peer0-org1.service
sudo systemctl start fabric-peer0-org1.service

#peer channel create -o orderer.car.com:7050 -c fabcar -f /etc/hyperledger/configtx/fabcar.tx --outputBlock fabcar.block -t 60s
peer channel create -o orderer.car.com:7050 -c carsales -f /etc/hyperledger/configtx/carsales.tx --outputBlock /etc/hyperledger/configtx/carsales.block -t 30s # &> carsales.log # --cafile ~/fabric/ca-cert.pem
# should output carsales.block
# TODO: try outputting carsales.block directly to /etc/hyperledger

#peer channel join -b /etc/hyperledger/configtx/carsales.block
#peer channel list



