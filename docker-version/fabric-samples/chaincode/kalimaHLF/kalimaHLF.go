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
// id - letter C followed by a sequence of 6 digits
// firstname - first name
// lastname - last name
// party - political party affiliation
type Candidate struct {
	Firstname string `json:"firstname"`
	Lastname  string `json:"lastname"`
	Party     string `json:"party"`
}

// Issue describes basic details of what makes up an issue
// id - letter I followed by a sequence of 6 digits
// name - short description of issue
type Issue struct {
	Name   string `json:"name"`
}

// Voter describes basic details of what makes up a voter
// id - letter V followed by a sequence of 6 digits
// VoterID - id of voter that cast vote
// CandidateID - id of candidate vote was cast for
// IssueID - id of issue vote was cast for
type Vote struct {
	VoterID     string `json:"voterID"`
	CandidateID string `json:"candidateID"`
	IssueID     string `json:"issueID"`
}

// CandidateQueryResult structure used for handling result of a Candidate query
type CandidateQueryResult struct {
	Key    string `json:"Key"`
	Record *Candidate
}

// IssueQueryResult structure used for handling result of an Issue query
type IssueQueryResult struct {
	Key    string `json:"Key"`
	Record *Issue
}

// VoteQueryResult structure used for handling result of an Vote query
type VoteQueryResult struct {
	Key    string `json:"Key"`
	Record *Vote
}

// InitLedger adds a base set of candidates to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	issues := []Issue{
		Issue{Name: "climate"},
		Issue{Name: "immigration"},
		Issue{Name: "e-waste"},
	}
	candidates := []Candidate{
		Candidate{Firstname: "George", Lastname: "Washington", Party: "Independent"},
		Candidate{Firstname: "John", Lastname: "Kennedy", Party: "Democrat"},
		Candidate{Firstname: "Abraham", Lastname: "Lincoln", Party: "Republican"},
	}
	votes := []Vote{
		Vote{VoterID: "E000000", CandidateID: "C000000", IssueID: "I000002"},
		Vote{VoterID: "E000001", CandidateID: "C000000", IssueID: "I000002"},
		Vote{VoterID: "E000002", CandidateID: "C000000", IssueID: "I000002"},
	}

	for i, issue := range issues {
		issueAsBytes, _ := json.Marshal(issue)
		err := ctx.GetStub().PutState("I00000"+strconv.Itoa(i), issueAsBytes)

		if err != nil {
			return fmt.Errorf("Failed to put to world state. %s", err.Error())
		}
	}

	for i, candidate := range candidates {
		candidateAsBytes, _ := json.Marshal(candidate)
		err := ctx.GetStub().PutState("C00000"+strconv.Itoa(i), candidateAsBytes)

		if err != nil {
			return fmt.Errorf("Failed to put to world state. %s", err.Error())
		}
	}

	for i, vote := range votes {
		voteAsBytes, _ := json.Marshal(vote)
		err := ctx.GetStub().PutState("V00000"+strconv.Itoa(i), voteAsBytes)

		if err != nil {
			return fmt.Errorf("Failed to put to world state. %s", err.Error())
		}
	}

	return nil
}

// AddIssue adds a new candidate to the world state using given details
func (s *SmartContract) AddIssue(ctx contractapi.TransactionContextInterface, id string, name string) error {
	issue := Issue{
		Name: name,
	}
	
	issueAsBytes, _ := json.Marshal(issue)
	return ctx.GetStub().PutState(id, issueAsBytes)
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

// AddVote adds a new vote to the world state using given details
func (s *SmartContract) AddVote(ctx contractapi.TransactionContextInterface, id string, voterID string, candidateID string, issueID string) error {
	vote := Vote{
		VoterID: voterID,
		CandidateID: candidateID,
		IssueID: issueID,
	}
	
	voteAsBytes, _ := json.Marshal(vote)
	return ctx.GetStub().PutState(id, voteAsBytes)
}

// ViewIssue returns issue details based on given id
func (s *SmartContract) ViewIssue(ctx contractapi.TransactionContextInterface, id string) (*Issue, error) {
	issueAsBytes, err := ctx.GetStub().GetState(id)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if issueAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", id)
	}

	issue := new(Issue)
	_ = json.Unmarshal(issueAsBytes, issue)

	return issue, nil
}

// ViewCandidate returns candidate details based on given id
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

// ViewVote returns vote details based on given id
func (s *SmartContract) ViewVote(ctx contractapi.TransactionContextInterface, id string) (*Vote, error) {
	voteAsBytes, err := ctx.GetStub().GetState(id)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if voteAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", id)
	}

	vote := new(Vote)
	_ = json.Unmarshal(voteAsBytes, vote)

	return vote, nil
}

// QueryAllIssues returns all issues found in world state
func (s *SmartContract) QueryAllIssues(ctx contractapi.TransactionContextInterface) ([]IssueQueryResult, error) {
	startKey := "I000000"
	endKey := "I999999"
	
	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []IssueQueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		issue := new(Issue)
		_ = json.Unmarshal(queryResponse.Value, issue)

		issueQueryResult := IssueQueryResult{Key: queryResponse.Key, Record: issue}
		results = append(results, issueQueryResult)
	}

	return results, nil
}


// QueryAllCandidates returns all candidates found in world state
func (s *SmartContract) QueryAllCandidates(ctx contractapi.TransactionContextInterface) ([]CandidateQueryResult, error) {
	startKey := "C000000"
	endKey := "C999999"
	
	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []CandidateQueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		candidate := new(Candidate)
		_ = json.Unmarshal(queryResponse.Value, candidate)

		candidateQueryResult := CandidateQueryResult{Key: queryResponse.Key, Record: candidate}
		results = append(results, candidateQueryResult)
	}

	return results, nil
}

// QueryAllVotes returns all votes found in world state
func (s *SmartContract) QueryAllVotes(ctx contractapi.TransactionContextInterface) ([]VoteQueryResult, error) {
	startKey := "V000000"
	endKey := "V999999"
	
	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)

	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []VoteQueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		vote := new(Vote)
		_ = json.Unmarshal(queryResponse.Value, vote)
		
		voteQueryResult := VoteQueryResult{Key: queryResponse.Key, Record: vote}
		results = append(results, voteQueryResult)
	}

	return results, nil
}

// VerifyVote allows voter to use their quantum signature to verify their vote was recorded properly in blockchain
func (s *SmartContract) VerifyVote(ctx contractapi.TransactionContextInterface, id string) ([]VoteQueryResult, error) {
	queryString := fmt.Sprintf("{\"selector\":{\"voterID\":\"%s\"}}", id)	
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	results := []VoteQueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		vote := new(Vote)
		_ = json.Unmarshal(queryResponse.Value, vote)
		
		voteQueryResult := VoteQueryResult{Key: queryResponse.Key, Record: vote}
		results = append(results, voteQueryResult)
	}

	return results, nil
}


// TallyCandidateVotes returns all votes for a given candidate id found in world state
//func (s *SmartContract) TallyCandidateVotes(ctx contractapi.TransactionContextInterface, id string) ([]VoteQueryResult, error) {
func (s *SmartContract) TallyCandidateVotes(ctx contractapi.TransactionContextInterface, id string) (int, error) {
	queryString := fmt.Sprintf("{\"selector\":{\"candidateID\":\"%s\"}}", id)	
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
		
	if err != nil {
		return 0, err
	}
	defer resultsIterator.Close()

	//results := []VoteQueryResult{}

	count := 0
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return 0, err
		}

		vote := new(Vote)
		_ = json.Unmarshal(queryResponse.Value, vote)
		
		//voteQueryResult := VoteQueryResult{Key: queryResponse.Key, Record: vote}
		//results = append(results, voteQueryResult)
		count++
	}

	//return results, nil
	return count, nil		// only return count
}

// TallyIssueVotes returns all votes for a given candidate id found in world state
//func (s *SmartContract) TallyCandidateVotes(ctx contractapi.TransactionContextInterface, id string) ([]VoteQueryResult, error) {
func (s *SmartContract) TallyIssueVotes(ctx contractapi.TransactionContextInterface, id string) (int, error) {
	queryString := fmt.Sprintf("{\"selector\":{\"issueID\":\"%s\"}}", id)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
		
	if err != nil {
		return 0, err
	}
	defer resultsIterator.Close()

	//results := []VoteQueryResult{}

	count := 0
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return 0, err
		}

		vote := new(Vote)
		_ = json.Unmarshal(queryResponse.Value, vote)
		
		//voteQueryResult := VoteQueryResult{Key: queryResponse.Key, Record: vote}
		//results = append(results, voteQueryResult)
		count++
	}

	//return results, nil
	return count, nil		// only return count
}

// UpdateIssue updates issue w/ the given details
func (s *SmartContract) UpdateIssue(ctx contractapi.TransactionContextInterface, id string, name string) error {
	issue, err := s.ViewIssue(ctx, id)

	if err != nil {
		return err
	}

	issue.Name = name

	issueAsBytes, _ := json.Marshal(issue)

	return ctx.GetStub().PutState(id, issueAsBytes)
}

// UpdateCandidate updates the candidate w/ the given details
func (s *SmartContract) UpdateCandidate(ctx contractapi.TransactionContextInterface, id string, firstname string, lastname string, party string) error {
	candidate, err := s.ViewCandidate(ctx, id)

	if err != nil {
		return err
	}
	
	candidate.Firstname = firstname
	candidate.Lastname = lastname
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
