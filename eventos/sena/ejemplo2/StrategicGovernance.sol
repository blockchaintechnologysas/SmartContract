// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.5/utils/structs/EnumerableSet.sol";

contract DecisionGovernance is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    address public constant BT_AI_TOKEN = 0x01667E6fedBF020df3C51EB70Ab8420194332a8b;
    uint256 public constant VOTING_PERIOD = 1 days;
    
    struct Proposal {
        uint256 id;
        string description;
        uint256 endDate;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) votes;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    EnumerableSet.AddressSet private eligibleVoters;
    
    event ProposalCreated(uint256 id, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool result);

    modifier onlyEligible() {
        require(hasVotingRight(msg.sender), "No tienes derechos de voto");
        _;
    }

    function createProposal(string memory description) public onlyEligible {
        uint256 proposalId = proposalCount++;
        Proposal storage p = proposals[proposalId];
        
        p.id = proposalId;
        p.description = description;
        p.endDate = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(proposalId, msg.sender, description);
    }
    
    function vote(uint256 proposalId, bool support) public onlyEligible {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp <= p.endDate, "Periodo de votacion terminado");
        require(!p.votes[msg.sender], "Ya votaste");
        
        p.votes[msg.sender] = true;
        
        if (support) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }
        
        emit Voted(proposalId, msg.sender, support);
    }
    
    function executeProposal(uint256 proposalId) public onlyOwner {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.endDate, "Votacion en curso");
        require(!p.executed, "Propuesta ya ejecutada");
        
        bool result = p.yesVotes > p.noVotes;
        p.executed = true;
        
        emit ProposalExecuted(proposalId, result);
    }
    
    function hasVotingRight(address account) public view returns (bool) {
        return eligibleVoters.contains(account);
    }
    
    function addVoter(address voter) public onlyOwner {
        eligibleVoters.add(voter);
    }
    
    function removeVoter(address voter) public onlyOwner {
        eligibleVoters.remove(voter);
    }
    
    function getVoterCount() public view returns (uint256) {
        return eligibleVoters.length();
    }
}
