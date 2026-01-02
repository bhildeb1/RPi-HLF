/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing an e-voting election
type SmartContract struct {
	contractapi.Contract
}

// Candidate describes basic details of what makes up a candidate
// id - sequence of 9 alphanumeric letters
// firstname - first name
// lastname - last name
// party - political party affiliation
type Candidate struct {
	Firstname string `json:"firstname"`
	Lastname  string `json:"lastname"`
	Party     string `json:"party"`
}

// QueryResult structure used for handling result of query
type QueryResult struct {
	Key    string `json:"Key"`
	Record *Candidate
}

// TODO: rename candidateAsBytes to candidateAsBytes
// InitLedger adds a base set of candidates to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	candidates := []Candidate{
		Candidate{Firstname: "Brian", Lastname: "Hildebrand", Party: "Libertarian"},
		Candidate{Firstname: "John", Lastname: "Kennedy", Party: "Democrat"},
		Candidate{Firstname: "Abraham", Lastname: "Lincoln", Party: "Republican"},
	}

	for i, candidate := range candidates {
		candidateAsBytes, _ := json.Marshal(candidate)
		err := ctx.GetStub().PutState("H8VA0123"+strconv.Itoa(i), candidateAsBytes)

		if err != nil {
			return fmt.Errorf("Failed to put to world state. %s", err.Error())
		}
	}

	return nil
}

// AddCandidate adds a new candidate to the world state using given details
func (s *SmartContract) AddCandidate(ctx contractapi.TransactionContextInterface, id string, firstname string, lastname string, party string) error {
	candidate := Candidate{
		Firstname: firstname,
		Lastname: lastname,
		Party: party,
	}
	
	candidateAsBytes, _ := json.Marshal(candidate)
	return ctx.GetStub().PutState(id, candidateAsBytes)
}

// ViewCandidate returns candidate based on given id
func (s *SmartContract) ViewCandidate(ctx contractapi.TransactionContextInterface, id string) (*Candidate, error) {
	candidateAsBytes, err := ctx.GetStub().GetState(id)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if candidateAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", id)
	}

	candidate := new(Candidate)
	_ = json.Unmarshal(candidateAsBytes, candidate)

	return candidate, nil
}

// QueryAllCandidates returns all candidates found in world state
func (s *SmartContract) QueryAllCandidates(ctx contractapi.TransactionContextInterface) ([]QueryResult, error) {
	startKey := "H8VA01230"
	endKey := "H8VA012399"
	
	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []QueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		candidate := new(Candidate)
		_ = json.Unmarshal(queryResponse.Value, candidate)

		queryResult := QueryResult{Key: queryResponse.Key, Record: candidate}
		results = append(results, queryResult)
	}

	return results, nil
}


// UpdateCandidate updates the candidate w/ the given details
func (s *SmartContract) UpdateCandidate(ctx contractapi.TransactionContextInterface, id string, party string) error {
	candidate, err := s.ViewCandidate(ctx, id)

	if err != nil {
		return err
	}

	candidate.Party = party

	candidateAsBytes, _ := json.Marshal(candidate)

	return ctx.GetStub().PutState(id, candidateAsBytes)
}

func main() {

	chaincode, err := contractapi.NewChaincode(new(SmartContract))

	if err != nil {
		fmt.Printf("Error create KalimaHLF chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting KalimaHLF chaincode: %s", err.Error())
	}
}
