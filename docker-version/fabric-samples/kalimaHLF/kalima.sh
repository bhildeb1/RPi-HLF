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

PARAM1=${1:-"help"}

if [ $PARAM1 = "candidates" ]; then
	# output all candidates
	# Usage: ./kalima.sh candidates
	QUERY_FUNCTION='{"function":"QueryAllCandidates","Args":[]}'
	${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c ${QUERY_FUNCTION} \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "issues" ]; then
	# output all issues
	# Usage: ./kalima.sh issues
	QUERY_FUNCTION='{"function":"QueryAllIssues","Args":[]}'
	${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c ${QUERY_FUNCTION} \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "votes" ]; then
	# output all voters
	# Usage: ./kalima.sh votes
	QUERY_FUNCTION='{"function":"QueryAllVotes","Args":[]}'
	
	CC_QUERY=`(${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c ${QUERY_FUNCTION} \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .)`
	   		
	echo "$CC_QUERY"
elif [ $PARAM1 = "tallyCandidateVotes" ]; then
	# tally up votes for candidate based on given id
	# Usage: ./kalima.sh tallyCandidateVotes [id]
	# E.g.:  ./kalima.sh tallyCandidateVotes C000002
	${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["TallyCandidateVotes","'$2'"]}' \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "tallyIssueVotes" ]; then
	# tally up votes for issue based on given id
	# Usage: ./kalima.sh tallyIssueVotes [id]
	# E.g.:  ./kalima.sh tallyIssueVotes I000002
	${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["TallyIssueVotes","'$2'"]}' \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .
elif [ $PARAM1 = "verifyVote" ]; then
	# verify vote was recorded properly in blockchain by given voter id (quantum signature) 
	# Usage: ./kalima.sh verifyVote [voter id]
	# E.g.:  ./kalima.sh verifyVote V000002
	candidateID=`${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["VerifyVote","'$2'"]}' \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .[0].Record.candidateID`
	candidateID="${candidateID//\"/}"
	
	issueID=`${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["VerifyVote","'$2'"]}' \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .[0].Record.issueID`
	issueID="${issueID//\"/}"

	candidate=`${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["ViewCandidate","'$candidateID'"]}' \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .`

	issue=`${PEER1_ORG1} chaincode query \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["ViewIssue","'$issueID'"]}' \
	   --peerAddresses peer1.org1.example.com:8051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   | jq .`
	
	echo "candidateID: $candidateID"
	echo "candidate: $candidate"
	echo "issueID: $issueID"
	echo "issue: $issue"
elif [ $PARAM1 = "candidate" ]; then
	# query ind'l candidate using given id
	# Usage: ./kalima.sh candidate [id]
	# E.g.:  ./kalima.sh candidate C123456
	candidateID=$2
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
elif [ $PARAM1 = "issue" ]; then
	# query ind'l issue using given id
	# Usage: ./kalima.sh issue [id]
	# E.g.:  ./kalima.sh issue I123456
	QUERY_FUNCTION_A='{"function":"ViewIssue","Args":["'
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
elif [ $PARAM1 = "vote" ]; then
	# query ind'l voter using given id
	# Usage: ./kalima.sh vote [id]
	# E.g.:  ./kalima.sh vote V123456
	QUERY_FUNCTION_A='{"function":"ViewVote","Args":["'
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
elif [ $PARAM1 = "addCandidate" ]; then
	# create new candidate - adds new candidate to world state w/ given details	
	# Usage: ./kalima.sh addCandidate [first name] [last name] [party]
	# E.g.:  ./kalima.sh addCandidate George Washington Federalist
	id="C$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))"
	first=${2:-"John"}
	last=${3:-"Doe"}
	party=${4:-"Undeclared"}
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
elif [ $PARAM1 = "addIssue" ]; then
	# create new issue - adds new issue to world state w/ given details	
	# Usage: ./kalima.sh addIssue [issue name]
	# E.g.:  ./kalima.sh addIssue e-waste
	id="I$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))"
	name=${2:-"e-waste"}
	${PEER1_ORG1} chaincode invoke \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["AddIssue","'$id'","'$name'"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent \
	   --waitForEventTimeout 300s
elif [ $PARAM1 = "addVote" ]; then
	# create new vote - adds new vote to world state w/ given details	
	# Usage: ./kalima.sh addVote [voter id] [candidate id]
	# E.g.:  ./kalima.sh addVote E000000 C000000
	id="V$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))$((RANDOM % 10))"
	voterID=$2
	candidateID=$3
	${PEER1_ORG1} chaincode invoke \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["AddVote","'$id'","'$voterID'","'$candidateID'"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent \
	   --waitForEventTimeout 300s
elif [ $PARAM1 = "updateCandidate" ]; then
	# update candidate details - updates candidate using given details
	# Usage: ./kalima.sh updateCandidate [id] [first name] [last name] [party]
	# E.g.:  ./kalima.sh updateCandidate C123456 Jimmy McMillan RentTooHigh
	id=$2
	first=$3
	last=$4
	party=$5
	${PEER1_ORG1} chaincode invoke \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["UpdateCandidate","'$id'","'$first'","'$last'","'$party'"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent
elif [ $PARAM1 = "updateIssue" ]; then
	# update issue details - updates issue using given details
	# Usage: ./kalima.sh updateIssue [id] [issue name]
	# E.g.:  ./kalima.sh updateIssue I000002 e-waste
	id=$2
	name=$3
	${PEER1_ORG1} chaincode invoke \
	   -C aether \
	   -n kalima \
	   -c '{"Args":["UpdateIssue","'$id'","'$name'"]}' \
	   --peerAddresses peer0.org1.example.com:7051 \
	   --peerAddresses peer0.org2.example.com:9051 \
	   --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} \
	   --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE} \
	   --waitForEvent
else
	echo
	echo "KalimaHLF Reference:"
	echo "Use provided bash scripts (or write your own) to interact with KalimaHLF blockchain:"
        echo
	echo "View all candidates:    ./kalima.sh candidates"
	echo "View all issues:        ./kalima.sh issues"
	echo "View all votes:         ./kalima.sh votes"
	echo
	echo "Tally candidate votes:  ./kalima.sh tallyCandidateVotes [candidate id]"
	echo "Tally issue votes:      ./kalima.sh tallyIssueVotes [issue id]"
	echo "Verify vote:            ./kalima.sh verifyVote [voter id]"
	echo
	echo "View candidate by id:   ./kalima.sh candidate [id]"
	echo "View issue by id:       ./kalima.sh issue [id]"
	echo "View vote by id:        ./kalima.sh vote [id]"
	echo
	echo "Add candidate:          ./kalima.sh addCandidate [first name] [last name] [party]"
	echo "Add issue:              ./kalima.sh addIssue [issue name]"
	echo "Add vote:               ./kalima.sh addVote [voter id] [candidate id]"
	echo "Update candidate:       ./kalima.sh updateCandidate [id] [first name] [last name] [party]"
	echo "Update issue:           ./kalima.sh updateIssue [id] [issue name]"
	echo
fi

