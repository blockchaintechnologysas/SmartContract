// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.9.5/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/utils/structs/EnumerableSet.sol";

contract DAO is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public governanceToken;
    IERC20 public actionToken;
    bool public proposalsOpen = true;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address payable recipient;
        uint256 amount; // en ETH (no wei)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public votingDuration = 3 days;

    EnumerableSet.AddressSet private members;

    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        string description,
        address recipient,
        uint256 amount
    );
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsTransferred(address indexed recipient, uint256 amount);

    constructor(address _governanceToken, address _actionToken) {
        governanceToken = IERC20(_governanceToken);
        actionToken = IERC20(_actionToken);
    }

    function setProposalsStatus(bool _status) external onlyOwner {
        proposalsOpen = _status;
    }

    function setVotingDuration(uint256 _durationInDays) external onlyOwner {
        votingDuration = _durationInDays * 1 days;
    }

    function createProposal(
        string memory _description,
        address payable _recipient,
        uint256 _amountInEth
    ) external {
        require(proposalsOpen, "Proposals are currently closed");
        require(
            governanceToken.balanceOf(msg.sender) > 0,
            "Must hold governance tokens to propose"
        );

        uint256 amountInWei = _amountInEth * 1 ether;
        require(address(this).balance >= amountInWei, "DAO has insufficient funds");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.recipient = _recipient;
        newProposal.amount = _amountInEth;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;

        emit ProposalCreated(
            proposalCount,
            msg.sender,
            _description,
            _recipient,
            _amountInEth
        );
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.voters[msg.sender], "Already voted");
        require(
            actionToken.balanceOf(msg.sender) > 0,
            "Must hold action tokens to vote"
        );

        uint256 votingWeight = actionToken.balanceOf(msg.sender);
        proposal.voters[msg.sender] = true;

        if (_support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }

        emit Voted(_proposalId, msg.sender, _support, votingWeight);

        // Check if quorum is met and execute if yes
        checkAndExecuteProposal(_proposalId);
    }

    function checkAndExecuteProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        
        if (block.timestamp > proposal.endTime && !proposal.executed) {
            uint256 totalActionSupply = actionToken.totalSupply();
            uint256 quorum = (totalActionSupply * 51) / 100; // 51% del total
            
            if (proposal.votesFor > quorum) {
                executeProposal(_proposalId);
            }
        }
    }

    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 totalActionSupply = actionToken.totalSupply();
        uint256 quorum = (totalActionSupply * 51) / 100;
        
        require(proposal.votesFor > quorum, "Quorum not met");

        proposal.executed = true;
        uint256 amountInWei = proposal.amount * 1 ether;
        proposal.recipient.transfer(amountInWei);

        emit ProposalExecuted(_proposalId);
        emit FundsTransferred(proposal.recipient, amountInWei);
    }

    function getProposalVotes(uint256 _proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.votesFor, proposal.votesAgainst);
    }

    function hasVoted(uint256 _proposalId, address _voter) public view returns (bool) {
        return proposals[_proposalId].voters[_voter];
    }

    // Función para recibir ETH en el contrato
    receive() external payable {}
}
