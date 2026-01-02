#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error
set -ex

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)

CC_RUNTIME_LANGUAGE=golang
CC_SRC_PATH=/opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode/kalimaHLF

echo Vendoring Go dependencies ...
pushd ../chaincode/kalimaHLF
GO111MODULE=on go mod vendor
popd
echo Finished vendoring Go dependencies

# clean the keystore
rm -rf ./hfc-key-store

# launch network; create channel and join peer to channel
pushd ../first-network
echo y | ./byfn.sh down
echo y | ./byfn.sh up -c aether -a -n -s couchdb
popd

CONFIG_ROOT=/opt/gopath/src/github.com/hyperledger/fabric/peer
ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
ORG2_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
ORG2_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
ORDERER_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

PEER0_ORG1="docker exec
-e CORE_PEER_LOCALMSPID=Org1MSP
-e CORE_PEER_ADDRESS=peer0.org1.example.com:7051
-e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH}
-e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE}
cli
peer
--tls=true
--cafile=${ORDERER_TLS_ROOTCERT_FILE}
--orderer=orderer.example.com:7050"

PEER1_ORG1="docker exec
-e CORE_PEER_LOCALMSPID=Org1MSP
-e CORE_PEER_ADDRESS=peer1.org1.example.com:8051
-e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH}
-e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE}
cli
peer
--tls=true
--cafile=${ORDERER_TLS_ROOTCERT_FILE}
--orderer=orderer.example.com:7050"

PEER0_ORG2="docker exec
-e CORE_PEER_LOCALMSPID=Org2MSP
-e CORE_PEER_ADDRESS=peer0.org2.example.com:9051
-e CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH}
-e CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE}
cli
peer
--tls=true
--cafile=${ORDERER_TLS_ROOTCERT_FILE}
--orderer=orderer.example.com:7050"

PEER1_ORG2="docker exec
-e CORE_PEER_LOCALMSPID=Org2MSP
-e CORE_PEER_ADDRESS=peer1.org2.example.com:10051
-e CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH}
-e CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE}
cli
peer
--tls=true
--cafile=${ORDERER_TLS_ROOTCERT_FILE}
--orderer=orderer.example.com:7050"

echo "Packaging smart contract on peer0.org1.example.com"
${PEER0_ORG1} lifecycle chaincode package \
  kalima.tar.gz \
  --path "$CC_SRC_PATH" \
  --lang "$CC_RUNTIME_LANGUAGE" \
  --label kalima

echo "Installing smart contract on peer0.org1.example.com"
${PEER0_ORG1} lifecycle chaincode install \
  kalima.tar.gz

echo "Installing smart contract on peer1.org1.example.com"
${PEER1_ORG1} lifecycle chaincode install \
  kalima.tar.gz

echo "Determining package ID for smart contract on peer0.org1.example.com"
REGEX='Package ID: (.*), Label: kalima'
if [[ `${PEER0_ORG1} lifecycle chaincode queryinstalled` =~ $REGEX ]]; then
  PACKAGE_ID_ORG1=${BASH_REMATCH[1]}
else
  echo Could not find package ID for kalimaHLF chaincode on peer0.org1.example.com
  exit 1
fi

echo "Approving smart contract for org1"
${PEER0_ORG1} lifecycle chaincode approveformyorg \
  --package-id ${PACKAGE_ID_ORG1} \
  --channelID aether \
  --name kalima \
  --version 1.0 \
  --signature-policy "AND('Org1MSP.member','Org2MSP.member')" \
  --sequence 1 \
  --waitForEvent

echo "Packaging smart contract on peer0.org2.example.com"
${PEER0_ORG2} lifecycle chaincode package \
  kalima.tar.gz \
  --path "$CC_SRC_PATH" \
  --lang "$CC_RUNTIME_LANGUAGE" \
  --label kalima

echo "Installing smart contract on peer0.org2.example.com"
${PEER0_ORG2} lifecycle chaincode install kalima.tar.gz

echo "Installing smart contract on peer1.org2.example.com"
${PEER1_ORG2} lifecycle chaincode install kalima.tar.gz

echo "Determining package ID for smart contract on peer0.org2.example.com"
REGEX='Package ID: (.*), Label: kalima'
if [[ `${PEER0_ORG2} lifecycle chaincode queryinstalled` =~ $REGEX ]]; then
  PACKAGE_ID_ORG2=${BASH_REMATCH[1]}
else
  echo Could not find package ID for kalimaHLF chaincode on peer0.org2.example.com
  exit 1
fi

echo "Approving smart contract for org2"
${PEER0_ORG2} lifecycle chaincode approveformyorg \
  --package-id ${PACKAGE_ID_ORG2} \
  --channelID aether \
  --name kalima \
  --version 1.0 \
  --signature-policy "AND('Org1MSP.member','Org2MSP.member')" \
  --sequence 1 \
  --waitForEvent

echo "Committing smart contract"
${PEER0_ORG1} lifecycle chaincode commit \
  --channelID aether \
  --name kalima \
  --version 1.0 \
  --signature-policy "AND('Org1MSP.member','Org2MSP.member')" \
  --sequence 1 \
  --waitForEvent \
  --peerAddresses peer0.org1.example.com:7051 \
  --peerAddresses peer0.org2.example.com:9051 \
  --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
  --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE}

echo "Submitting initLedger transaction to smart contract on channel 'aether'"
echo "The transaction is sent to all of the peers so that chaincode is built before receiving the following requests"
${PEER0_ORG1} chaincode invoke \
  -C aether \
  -n kalima \
  -c '{"function":"initLedger","Args":[]}' \
  --waitForEvent \
  --waitForEventTimeout 300s \
  --peerAddresses peer0.org1.example.com:7051 \
  --peerAddresses peer0.org2.example.com:9051 \
  --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
  --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE}

# Temporary workaround (see FAB-15897) - cannot invoke across all four peers at the same time, so use a query to build
# the chaincode across the remaining peers.
${PEER1_ORG1} chaincode query \
  -C aether \
  -n kalima \
  -c '{"function":"QueryAllCandidates","Args":[]}' \
  --peerAddresses peer1.org1.example.com:8051 \
  --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE}
${PEER1_ORG2} chaincode query \
  -C aether \
  -n kalima \
  -c '{"function":"QueryAllCandidates","Args":[]}' \
  --peerAddresses peer1.org2.example.com:10051 \
  --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE}

cat <<EOF

Total setup execution time : $(($(date +%s) - starttime)) secs ...

KalimaHLF Reference:
  Use provided bash scripts (or write your own) to interact with KalimaHLF blockchain.
  
  .queryLedger.sh all		# output all cars
  .queryLedger.sh car		# query ind'l car using given id
  .queryLedger.sh create	# create new car
  .queryFabric.sh assign	# change car owner
  ...
  AddCandidate
  
  More coming! Stay tuned!!! ...
  
EOF
