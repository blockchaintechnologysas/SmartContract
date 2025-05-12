// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title BT&AI DAO Governance - Sistema de Gobernanza para BT&AI Token
 * @notice Contrato que funciona con tu token existente en 0x01667E6fedBF020df3C51EB70Ab8420194332a8b
 */
contract BTAI_DAO is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    // Dirección de tu token existente (inmutable)
    address public constant BT_AI_TOKEN = 0x01667E6fedBF020df3C51EB70Ab8420194332a8b;
    
    // Configuración de la DAO
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant BOARD_TERM = 730 days; // 2 años
    uint256 public constant QUORUM_PERCENTAGE = 51;
    uint256 public constant TOP_SHAREHOLDERS_COUNT = 10;
    
    // Estructuras de datos
    enum ProposalType { ECONOMIC, WRITTEN, BOARD_ELECTION }
    enum ProposalStatus { PENDING, ACTIVE, APPROVED, REJECTED, EXECUTED }
    
    struct Proposal {
        uint256 id;
        ProposalType pType;
        ProposalStatus status;
        address proposer;
        uint256 creationDate;
        uint256 endDate;
        string description;
        address tokenAddress;
        address targetAddress;
        uint256 amount;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) votes;
    }
    
    struct BoardPosition {
        string title;
        address holder;
        uint256 electionDate;
        uint256 nextElection;
    }
    
    struct Candidate {
        address candidateAddress;
        string position;
        uint256 votesReceived;
    }
    
    // Variables de estado
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    BoardPosition[] public boardPositions;
    Candidate[] public candidates;
    EnumerableSet.AddressSet private topShareholders;
    
    // Eventos
    event ProposalCreated(uint256 id, ProposalType pType, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalResolved(uint256 proposalId, bool approved);
    event BoardElected(string position, address elected, uint256 endTerm);
    event CandidateNominated(address candidate, string position);
    event VoteCasted(address voter, address candidate, string position, uint256 weight);

    constructor() {
        _initializeBoardPositions();
        _updateTopShareholders();
    }
    
    // Funciones principales de la DAO
    
    function createProposal(
        ProposalType pType,
        string memory description,
        address tokenAddress,
        address targetAddress,
        uint256 amount
    ) public {
        require(isTopShareholder(msg.sender), "Solo los 10 mayores accionistas pueden proponer");
        
        uint256 proposalId = proposalCount++;
        Proposal storage p = proposals[proposalId];
        
        p.id = proposalId;
        p.pType = pType;
        p.status = ProposalStatus.ACTIVE;
        p.proposer = msg.sender;
        p.creationDate = block.timestamp;
        p.endDate = block.timestamp + VOTING_PERIOD;
        p.description = description;
        
        if (pType == ProposalType.ECONOMIC) {
            require(tokenAddress != address(0), "Se requiere direccion del token");
            p.tokenAddress = tokenAddress;
            p.targetAddress = targetAddress;
            p.amount = amount;
        }
        
        emit ProposalCreated(proposalId, pType, msg.sender, description);
    }
    
    function vote(uint256 proposalId, bool support) public {
        Proposal storage p = proposals[proposalId];
        require(p.status == ProposalStatus.ACTIVE, "Votacion no activa");
        require(block.timestamp <= p.endDate, "Periodo de votacion terminado");
        require(!p.votes[msg.sender], "Ya votaste");
        
        uint256 weight = IERC20(BT_AI_TOKEN).balanceOf(msg.sender);
        require(weight > 0, "No tienes acciones para votar");
        
        p.votes[msg.sender] = true;
        
        if (support) {
            p.yesVotes += weight;
        } else {
            p.noVotes += weight;
        }
        
        emit Voted(proposalId, msg.sender, support, weight);
        _checkVoting(proposalId);
    }
    
    // Funciones para elecciones de junta directiva
    
    function nominateCandidate(address candidate, string memory position) public {
        require(isTopShareholder(msg.sender), "Solo los 10 mayores accionistas pueden nominar");
        require(_isValidPosition(position), "Cargo no valido");
        require(IERC20(BT_AI_TOKEN).balanceOf(candidate) > 0, "El candidato debe ser accionista");
        
        candidates.push(Candidate({
            candidateAddress: candidate,
            position: position,
            votesReceived: 0
        }));
        
        emit CandidateNominated(candidate, position);
    }
    
    function conductElections() public onlyOwner {
        require(block.timestamp >= boardPositions[0].nextElection, "Elecciones no habilitadas aun");
        
        for (uint i = 0; i < boardPositions.length; i++) {
            address winner = _determineWinner(boardPositions[i].title);
            
            if (winner != address(0)) {
                boardPositions[i].holder = winner;
                boardPositions[i].electionDate = block.timestamp;
                boardPositions[i].nextElection = block.timestamp + BOARD_TERM;
                emit BoardElected(boardPositions[i].title, winner, boardPositions[i].nextElection);
            }
        }
        
        delete candidates;
    }
    
    // Funciones de consulta
    
    function isTopShareholder(address shareholder) public view returns (bool) {
        return topShareholders.contains(shareholder);
    }
    
    function getBoardPositions() public view returns (BoardPosition[] memory) {
        return boardPositions;
    }
    
    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
    
    // Funciones internas
    
    function _initializeBoardPositions() internal {
        boardPositions.push(BoardPosition("Presidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Vicepresidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Secretario", address(0), 0, 0));
        boardPositions.push(BoardPosition("Fiscal", address(0), 0, 0));
        boardPositions.push(BoardPosition("Tesorero", address(0), 0, 0));
        boardPositions.push(BoardPosition("CEO", address(0), 0, 0));
    }
    
    function _updateTopShareholders() internal {
        // Implementación simplificada - en producción necesitarías ordenar los accionistas por balance
        // Esta es una versión básica que actualiza periódicamente los mayores accionistas
        delete topShareholders;
        
        // Nota: En una implementación real necesitarías un mecanismo más sofisticado
        // para identificar verdaderamente a los TOP_SHAREHOLDERS_COUNT mayores accionistas
    }
    
    function _checkVoting(uint256 proposalId) internal {
        Proposal storage p = proposals[proposalId];
        
        if (block.timestamp >= p.endDate) {
            uint256 totalVotes = p.yesVotes + p.noVotes;
            uint256 totalSupply = IERC20(BT_AI_TOKEN).totalSupply();
            
            if (totalVotes * 100 >= totalSupply * QUORUM_PERCENTAGE) {
                p.status = p.yesVotes > p.noVotes ? ProposalStatus.APPROVED : ProposalStatus.REJECTED;
            } else {
                p.status = ProposalStatus.REJECTED; // No se alcanzó quórum
            }
            
            emit ProposalResolved(proposalId, p.status == ProposalStatus.APPROVED);
        }
    }
    
    function _determineWinner(string memory position) internal view returns (address) {
        address winner = address(0);
        uint256 highestVotes = 0;
        
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i].position)) == keccak256(bytes(position))) {
                if (candidates[i].votesReceived > highestVotes) {
                    highestVotes = candidates[i].votesReceived;
                    winner = candidates[i].candidateAddress;
                }
            }
        }
        
        return winner;
    }
    
    function _isValidPosition(string memory position) internal view returns (bool) {
        for (uint i = 0; i < boardPositions.length; i++) {
            if (keccak256(bytes(boardPositions[i].title)) == keccak256(bytes(position))) {
                return true;
            }
        }
        return false;
    }
}
