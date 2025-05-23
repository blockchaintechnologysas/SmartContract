// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.5/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/utils/structs/EnumerableSet.sol";

contract GovernanceToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract CompanyDAO {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Token de gobernanza
    GovernanceToken public governanceToken;

    // Estructura para candidato
    struct Candidate {
        address wallet;
        uint256 votes;
    }

    // Estructura para posición
    struct Position {
        string title;
        mapping(uint256 => Candidate) candidatesMapping; // Usamos mapping en lugar de array
        uint256 candidatesCount;
        bool electionOpen;
        uint256 lastElectionTime;
        address currentHolder;
    }

    // Posiciones en la junta directiva
    Position[] public positions;
    
    // Socios con derecho a voto
    EnumerableSet.AddressSet private shareholders;

    // Configuración
    uint256 public constant ELECTION_INTERVAL = 2 * 365 days;
    uint256 public constant VOTING_DURATION = 1 days;

    // Eventos
    event ElectionStarted(uint256 timestamp);
    event VoteCast(address indexed voter, uint256 positionIndex, address candidate, uint256 votes);
    event ElectionResult(uint256 positionIndex, address winner, uint256 votes);
    event CandidateProposed(uint256 positionIndex, address candidate);

    constructor(address _governanceTokenAddress) {
        governanceToken = GovernanceToken(_governanceTokenAddress);
        
        // Inicializar las posiciones
        _addPosition("Presidente");
        _addPosition("Vicepresidente");
        _addPosition("Fiscal");
    }

    // Función interna para añadir posiciones
    function _addPosition(string memory title) internal {
        Position storage newPosition;
        newPosition.title = title;
        newPosition.electionOpen = false;
        newPosition.lastElectionTime = 0;
        newPosition.currentHolder = address(0);
        newPosition.candidatesCount = 0;
        
        positions.push(newPosition);
    }

    // Modificador para verificar si es socio
    modifier onlyShareholder() {
        require(governanceToken.balanceOf(msg.sender) > 0, "No eres socio");
        _;
    }

    // Iniciar proceso de elección
    function startElection() public onlyShareholder {
        require(canStartElection(), "No es tiempo de elecciones o ya hay una en curso");
        
        for (uint256 i = 0; i < positions.length; i++) {
            positions[i].electionOpen = true;
            positions[i].candidatesCount = 0; // Resetear contador de candidatos
            positions[i].lastElectionTime = block.timestamp;
        }
        
        emit ElectionStarted(block.timestamp);
    }

    // Verificar si se puede iniciar elección
    function canStartElection() public view returns (bool) {
        if (positions.length == 0) return false;
        
        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].electionOpen) {
                return false;
            }
        }
        
        return (block.timestamp - positions[0].lastElectionTime) >= ELECTION_INTERVAL;
    }

    // Proponer candidato para una posición
    function proposeCandidate(uint256 positionIndex, address candidateWallet) public onlyShareholder {
        require(positionIndex < positions.length, "Posicion invalida");
        require(positions[positionIndex].electionOpen, "Eleccion no esta abierta para esta posicion");
        
        // Verificar que el candidato no haya sido ya propuesto
        for (uint256 i = 0; i < positions[positionIndex].candidatesCount; i++) {
            require(
                positions[positionIndex].candidatesMapping[i].wallet != candidateWallet, 
                "Candidato ya propuesto"
            );
        }
        
        uint256 newCandidateIndex = positions[positionIndex].candidatesCount;
        positions[positionIndex].candidatesMapping[newCandidateIndex] = Candidate({
            wallet: candidateWallet,
            votes: 0
        });
        positions[positionIndex].candidatesCount++;
        
        emit CandidateProposed(positionIndex, candidateWallet);
    }

    // Votar por un candidato
    function vote(uint256 positionIndex, uint256 candidateIndex) public onlyShareholder {
        require(positionIndex < positions.length, "Posicion invalida");
        require(candidateIndex < positions[positionIndex].candidatesCount, "Candidato invalido");
        require(positions[positionIndex].electionOpen, "Eleccion no esta abierta para esta posicion");
        require(
            block.timestamp - positions[positionIndex].lastElectionTime <= VOTING_DURATION, 
            "Periodo de votacion ha terminado"
        );
        
        uint256 voteWeight = governanceToken.balanceOf(msg.sender);
        require(voteWeight > 0, "No tienes tokens para votar");
        
        positions[positionIndex].candidatesMapping[candidateIndex].votes += voteWeight;
        emit VoteCast(
            msg.sender, 
            positionIndex, 
            positions[positionIndex].candidatesMapping[candidateIndex].wallet, 
            voteWeight
        );
    }

    // Finalizar elección y declarar ganadores
    function finalizeElection() public onlyShareholder {
        require(canFinalizeElection(), "No se puede finalizar la eleccion aun");
        
        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].candidatesCount > 0) {
                address winner = positions[i].candidatesMapping[0].wallet;
                uint256 maxVotes = positions[i].candidatesMapping[0].votes;
                
                for (uint256 j = 1; j < positions[i].candidatesCount; j++) {
                    if (positions[i].candidatesMapping[j].votes > maxVotes) {
                        maxVotes = positions[i].candidatesMapping[j].votes;
                        winner = positions[i].candidatesMapping[j].wallet;
                    }
                }
                
                positions[i].currentHolder = winner;
                positions[i].electionOpen = false;
                emit ElectionResult(i, winner, maxVotes);
            }
        }
    }

    // Verificar si se puede finalizar la elección
    function canFinalizeElection() public view returns (bool) {
        if (positions.length == 0) return false;
        
        for (uint256 i = 0; i < positions.length; i++) {
            if (!positions[i].electionOpen) {
                return false;
            }
        }
        
        return (block.timestamp - positions[0].lastElectionTime) > VOTING_DURATION;
    }

    // Obtener información de candidatos para una posición
    function getCandidate(uint256 positionIndex, uint256 candidateIndex) 
        public 
        view 
        returns (address wallet, uint256 votes) 
    {
        require(positionIndex < positions.length, "Posicion invalida");
        require(candidateIndex < positions[positionIndex].candidatesCount, "Candidato invalido");
        
        Candidate storage candidate = positions[positionIndex].candidatesMapping[candidateIndex];
        return (candidate.wallet, candidate.votes);
    }

    // Obtener número de candidatos para una posición
    function getCandidatesCount(uint256 positionIndex) public view returns (uint256) {
        require(positionIndex < positions.length, "Posicion invalida");
        return positions[positionIndex].candidatesCount;
    }

    // Verificar si una dirección es actual miembro de la junta
    function isBoardMember(address wallet) public view returns (bool) {
        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].currentHolder == wallet) {
                return true;
            }
        }
        return false;
    }
}
