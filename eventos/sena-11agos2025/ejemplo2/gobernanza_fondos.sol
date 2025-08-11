// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/utils/structs/EnumerableSet.sol";

contract DAO is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public governanceToken;
    IERC20 public actionToken;
    bool public proposalsOpen = true;
    uint256 public votingDuration; // en segundos

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
    event MemberAdded(address indexed account);
    event MemberRemoved(address indexed account);

    /**
     * @param _governanceToken Dirección del token de gobernanza (para proponer)
     * @param _actionToken     Dirección del token de acción (pondera votos)
     * @param _votingDays      Duración de la votación en días
     * @param _members         Lista inicial de socios con derecho a participar
     */
    constructor(
        address _governanceToken,
        address _actionToken,
        uint256 _votingDays,
        address[] memory _members
    ) {
        require(_governanceToken != address(0) && _actionToken != address(0), "Token invalido");
        require(_votingDays > 0, "Dias de votacion deben ser > 0");

        governanceToken = IERC20(_governanceToken);
        actionToken = IERC20(_actionToken);
        votingDuration = _votingDays * 1 days;

        // Cargar socios iniciales
        for (uint256 i = 0; i < _members.length; i++) {
            if (_members[i] != address(0)) {
                members.add(_members[i]);
                emit MemberAdded(_members[i]);
            }
        }
    }

    // --- Configuración ---

    function setProposalsStatus(bool _status) external onlyOwner {
        proposalsOpen = _status;
    }

    function setVotingDuration(uint256 _durationInDays) external onlyOwner {
        require(_durationInDays > 0, "Dias deben ser > 0");
        votingDuration = _durationInDays * 1 days;
    }

    // --- Membresia ---

    function isMember(address account) public view returns (bool) {
        return members.contains(account);
    }

    function addMembers(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != address(0) && members.add(accounts[i])) {
                emit MemberAdded(accounts[i]);
            }
        }
    }

    function removeMembers(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (members.remove(accounts[i])) {
                emit MemberRemoved(accounts[i]);
            }
        }
    }

    function membersCount() external view returns (uint256) {
        return members.length();
    }

    // --- Propuestas y Votación ---

    function createProposal(
        string memory _description,
        address payable _recipient,
        uint256 _amountInEth
    ) external {
        require(proposalsOpen, "Proposals are currently closed");
        require(isMember(msg.sender), "Solo socios pueden proponer");
        require(
            governanceToken.balanceOf(msg.sender) > 0,
            "Debe tener governance tokens para proponer"
        );

        uint256 amountInWei = _amountInEth * 1 ether;
        require(address(this).balance >= amountInWei, "DAO sin fondos suficientes");

        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.description = _description;
        p.recipient = _recipient;
        p.amount = _amountInEth;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + votingDuration;

        emit ProposalCreated(p.id, msg.sender, _description, _recipient, _amountInEth);
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp <= p.endTime, "Voting period has ended");
        require(!p.executed, "Proposal already executed");
        require(!p.voters[msg.sender], "Already voted");
        require(isMember(msg.sender), "Solo socios pueden votar");
        require(acti
