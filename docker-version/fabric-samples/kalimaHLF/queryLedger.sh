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
	QUERY_FUNCTION='{"function":"QueryAllCandidates","Args":[]}'
	${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c ${QUERY_FUNCTION} \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "candidate" ]; then
	# query ind'l car using given id
	# Usage: ./queryLedger.sh candidate [id]
	# E.g.:  ./queryLedger.sh candidate H8VA01234
	QUERY_FUNCTION_A='{"function":"ViewCandidate","Args":["'
	QUERY_FUNCTION_B=$2
	QUERY_FUNCTION_C='"]}'
	QUERY_FUNCTION="$QUERY_FUNCTION_A$QUERY_FUNCTION_B$QUERY_FUNCTION_C"
	${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c ${QUERY_FUNCTION} \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "add" ]; then
	# create new candidate - adds new candidate to world state w/ given details	
	# Usage: ./queryLedger.sh add [firstname] [lastname] [party]
	# E.g.:  ./queryledger.sh add George Washington Federalist
	a=$((RANDOM % 10))
	b=$((RANDOM % 10))
	id="H8VA0123$a$b"
	echo "id: $id"
	first=${2:-"John"}
	last=${3:-"Doe"}
	party=${4:-"Democrat"}
	${PEER1_ORG1} chaincode invoke \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["AddCandidate","'$id'","'$first'","'$last'","'$party'"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent \
	   --waitForEventTimeout 300s
elif [ $PARAM1 = "update" ]; then
	# update candidate details - updates candidate details using given details
	# Usage: ./queryLedger.sh update [id] [party]
	# E.g.:  ./queryLedger.sh update H8VA01234 Republican
	id=$2
	party=$3
	${PEER1_ORG1} chaincode invoke \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["UpdateCandidate","'$id'","'$party'"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent
elif [ $PARAM1 = "all2" ]; then	
	${PEER1_ORG1} chaincode invoke \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["QueryAllCandidates"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent | jq .result
fi

# TODO: 
# > rewrite query inv'l car to be similar to create
# > rename queryLedger.sh to something that relects its ability to invoke!!!!
# > help param section



