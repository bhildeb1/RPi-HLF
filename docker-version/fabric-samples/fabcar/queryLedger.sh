#!/bin/bash

ORG1_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
ORG2_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

PEER1_ORG1="docker exec 
   -e CORE_PEER_LOCALMSPID=Org1MSP
   -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051
   -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
   -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE}
   cli peer
   --tls=true 
   --cafile=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
   --orderer=orderer.example.com:7050"

PARAM1=${1:-"all"}

if [ $PARAM1 = "help" ]; then
	echo "Help: Coming Soon!"
elif [ $PARAM1 = "all" ]; then
	# output all cars
	QUERY_FUNCTION='{"function":"queryAllCars","Args":[]}'
	${PEER1_ORG1} chaincode query \
	   -C mychannel \
	   -n fabcar \
	   -c ${QUERY_FUNCTION} \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "car" ]; then
	# query ind'l car using given id
	# Usage: ./queryLedger.sh car [id]
	# E.g.:  ./queryLedger.sh car CAR33
	QUERY_FUNCTION_A='{"function":"QueryCar","Args":["'
	QUERY_FUNCTION_B=${2:-"CAR0"}
	QUERY_FUNCTION_C='"]}'
	QUERY_FUNCTION="$QUERY_FUNCTION_A$QUERY_FUNCTION_B$QUERY_FUNCTION_C"
	${PEER1_ORG1} chaincode query \
	   -C mychannel \
	   -n fabcar \
	   -c ${QUERY_FUNCTION} \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "create" ]; then
	# create new car - adds new car to world state w/ given details
	# Usage: ./queryLedger.sh create [id] [maker] [model] [color] [owner]
	# E.g.:  ./queryledger.sh create CAR33 Jeep Wrangler blue Brian
	randomKey=$(date +"CAR%M%S%M%H%S")
	id=${2:-$randomKey}
	maker=${3:-"Jeep"}
	model=${4:-"Wrangler"}
	color=${5:-"blue"}
	owner=${6:-"Brian"}
	${PEER1_ORG1} chaincode invoke \
	   -C mychannel \
	   -n fabcar \
	   -c '{"Args":["createCar","'$id'","'$maker'","'$model'","'$color'","'$owner'" ]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent
elif [ $PARAM1 = "assign" ]; then
	# change car owner - updates car owner using given id & new owner name
	# Usage: ./queryLedger.sh assign [id] [owner]
	# E.g.:  ./queryLedger.sh assign CAR33 Bridget
	id=$2
	owner=$3
	${PEER1_ORG1} chaincode invoke \
	   -C mychannel \
	   -n fabcar \
	   -c '{"Args":["changeCarOwner","'$id'","'$owner'"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent
fi

# TODO: 
# > rewrite query inv'l car to be similar to create
# > rename queryLedger.sh to something that relects its ability to invoke!!!!
# > help param section
# > upload to github
