// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.5/utils/structs/EnumerableSet.sol";

contract BoardGovernance is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Configurables por constructor
    address public governanceToken;      // Dirección del token de gobernanza
    uint256 public votingPeriod;         // En segundos (días * 1 days) 
    uint256 public topShareholdersCount; // Número de top holders habilitados para proponer

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

    /**
     * @param _token Dirección del token de gobernanza
     * @param _votingDays Duración de la votación en días
     * @param _topShareholdersCount Número de top holders con privilegio de proponer
     */
    constructor(address _token, uint256 _votingDays, uint256 _topShareholdersCount) {
        require(_token != address(0), "Token invalido");
        require(_votingDays > 0, "Dias de votacion deben ser > 0");
        require(_topShareholdersCount > 0, "Top holders debe ser > 0");

        governanceToken = _token;
        votingPeriod = _votingDays * 1 days;
        topShareholdersCount = _topShareholdersCount;

        _initializeBoardPositions();
    }

    function createProposal(string memory description) public {
        require(isTopHolder(msg.sender), "Solo top holders pueden proponer");
        require(hasVotingRight(msg.sender), "Debes ser socio para proponer");

        uint256 proposalId = proposalCount++;
        Proposal storage p = proposals[proposalId];

        p.id = proposalId;
        p.description = description;
        p.endDate = block.timestamp + votingPeriod;

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
            // Aquí iría la lógica para ejecutar cambios en la junta directiva
            p.executed = true;
            emit ProposalExecuted(proposalId);
        }
    }

    // --- Helpers de elegibilidad ---

    function isTopHolder(address account) public view returns (bool) {
        return topHolders.contains(account);
    }

    function hasVotingRight(address account) public view returns (bool) {
        return eligibleVoters.contains(account);
    }

    // --- Inicialización de cargos ---

    function _initializeBoardPositions() internal {
        boardPositions.push(BoardPosition("Presidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Vicepresidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Secretario", address(0), 0, 0));
        boardPositions.push(BoardPosition("Fiscal", address(0), 0, 0));
        boardPositions.push(BoardPosition("Tesorero", address(0), 0, 0));
    }

    // --- Administración ---

    /// @notice Reemplaza el set de top holders por la lista provista, acotada a topShareholdersCount
    function updateTopHolders(address[] calldata holders) external onlyOwner {
        // Vaciar set actual
        uint256 len = topHolders.length();
        while (len > 0) {
            address a = topHolders.at(len - 1);
            topHolders.remove(a);
            len--;
        }

        // Agregar hasta topShareholdersCount
        uint256 limit = holders.length < topShareholdersCount ? holders.length : topShareholdersCount;
        for (uint256 j = 0; j < limit; j++) {
            if (holders[j] != address(0)) {
                topHolders.add(holders[j]);
            }
        }
    }

    function setEligibleVoters(address[] calldata voters, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < voters.length; i++) {
            if (allowed) {
                eligibleVoters.add(voters[i]);
            } else {
                eligibleVoters.remove(voters[i]);
            }
        }
    }

    /// @notice Cambia el número de top holders permitido (si lo quieres editable post-deploy)
    function setTopShareholdersCount(uint256 _count) external onlyOwner {
        require(_count > 0, "Top holders debe ser > 0");
        topShareholdersCount = _count;
    }

    // --- Utilidad opcional ---

    function votingTimeLeft(uint256 proposalId) external view returns (uint256) {
        Proposal storage p = proposals[proposalId];
        if (block.timestamp >= p.endDate) return 0;
        return p.endDate - block.timestamp;
    }
}
