// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/utils/structs/EnumerableSet.sol";

contract BoardGovernance is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    address public constant BT_AI_TOKEN = 0x01667E6fedBF020df3C51EB70Ab8420194332a8b;
    uint256 public constant TOP_SHAREHOLDERS_COUNT = 10;
    uint256 public constant VOTING_PERIOD = 7 days;
    
    struct Proposal {
        uint256 id;
        string description;
        uint256 endDate;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) votes;
    }
    
    struct BoardPosition {
        string title;
        address holder;
        uint256 electionDate;
        uint256 nextElection;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    BoardPosition[] public boardPositions;
    EnumerableSet.AddressSet private topHolders;
    EnumerableSet.AddressSet private eligibleVoters;
    
    event ProposalCreated(uint256 id, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event BoardMemberElected(string position, address member);

    constructor() {
        _initializeBoardPositions();
    }
    
    function createProposal(string memory description) public {
        require(isTopHolder(msg.sender), "Solo los 10 mayores holders pueden proponer");
        require(hasVotingRight(msg.sender), "Debes ser socio para proponer");
        
        uint256 proposalId = proposalCount++;
        Proposal storage p = proposals[proposalId];
        
        p.id = proposalId;
        p.description = description;
        p.endDate = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(proposalId, msg.sender, description);
    }
    
    function vote(uint256 proposalId, bool support) public {
        Proposal storage p = proposals[proposalId];
        require(hasVotingRight(msg.sender), "No tienes derechos para votar");
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
        
        if (p.yesVotes > p.noVotes) {
            // Lógica para ejecutar cambios en la junta directiva
            p.executed = true;
            emit ProposalExecuted(proposalId);
        }
    }
    
    function isTopHolder(address account) public view returns (bool) {
        return topHolders.contains(account);
    }
    
    function hasVotingRight(address account) public view returns (bool) {
        return eligibleVoters.contains(account);
    }
    
    function _initializeBoardPositions() internal {
        boardPositions.push(BoardPosition("Presidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Vicepresidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Secretario", address(0), 0, 0));
        boardPositions.push(BoardPosition("Fiscal", address(0), 0, 0));
        boardPositions.push(BoardPosition("Tesorero", address(0), 0, 0));
    }
    
    function updateTopHolders() public onlyOwner {
        // Lógica para actualizar los top 10 holders
        // Esto requeriría consultar los balances del token BT&AI
    }
}
