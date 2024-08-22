// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TheDexToken} from "./TheDexToken.sol";

contract Governance {
    TheDexToken public governanceToken;
    uint256 public proposalCount;
    uint256 public votingPeriod = 1 weeks;

    struct Proposal {
        address proposer;
        string description;
        uint256 voteCount;
        uint256 endTime;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event Voted(uint256 indexed proposalId, address voter);

    constructor(address _governanceToken) {
        governanceToken = TheDexToken(_governanceToken);
    }

    function createProposal(string calldata description) external {
        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.endTime = block.timestamp + votingPeriod;

        emit ProposalCreated(proposalCount, msg.sender, description);
    }

    function vote(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!proposal.voted[msg.sender], "Already voted");

        uint256 votingPower = governanceToken.balanceOf(msg.sender);
        require(votingPower > 0, "No voting power");

        proposal.voteCount += votingPower;
        proposal.voted[msg.sender] = true;

        emit Voted(proposalId, msg.sender);
    }
}
