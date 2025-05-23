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

    // Estructuras para la elección
    struct Candidate {
        address wallet;
        uint256 votes;
    }

    struct Position {
        string title;
        Candidate[] candidates;
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

    constructor(address _governanceTokenAddress) {
        governanceToken = GovernanceToken(_governanceTokenAddress);
        
        // Inicializar las posiciones
        positions.push(Position({
            title: "Presidente",
            candidates: new Candidate[](0),
            electionOpen: false,
            lastElectionTime: 0,
            currentHolder: address(0)
        }));
        
        positions.push(Position({
            title: "Vicepresidente",
            candidates: new Candidate[](0),
            electionOpen: false,
            lastElectionTime: 0,
            currentHolder: address(0)
        }));
        
        positions.push(Position({
            title: "Fiscal",
            candidates: new Candidate[](0),
            electionOpen: false,
            lastElectionTime: 0,
            currentHolder: address(0)
        }));
    }

    // Modificador para verificar si es socio
    modifier onlyShareholder() {
        require(governanceToken.balanceOf(msg.sender) > 0, "No eres socio");
        _;
    }

    // Iniciar proceso de elección (puede ser llamado por cualquier socio cuando es tiempo)
    function startElection() public onlyShareholder {
        require(canStartElection(), "No es tiempo de elecciones o ya hay una en curso");
        
        for (uint256 i = 0; i < positions.length; i++) {
            positions[i].electionOpen = true;
            delete positions[i].candidates;
            positions[i].lastElectionTime = block.timestamp;
        }
        
        emit ElectionStarted(block.timestamp);
    }

    // Verificar si se puede iniciar elección
    function canStartElection() public view returns (bool) {
        if (positions.length == 0) return false;
        
        // Verificar si ya hay una elección en curso
        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].electionOpen) {
                return false;
            }
        }
        
        // Verificar si ha pasado el intervalo desde la última elección
        return (block.timestamp - positions[0].lastElectionTime) >= ELECTION_INTERVAL;
    }

    // Proponer candidato para una posición
    function proposeCandidate(uint256 positionIndex, address candidateWallet) public onlyShareholder {
        require(positionIndex < positions.length, "Posicion invalida");
        require(positions[positionIndex].electionOpen, "Eleccion no esta abierta para esta posicion");
        
        // Verificar que el candidato no haya sido ya propuesto
        for (uint256 i = 0; i < positions[positionIndex].candidates.length; i++) {
            require(positions[positionIndex].candidates[i].wallet != candidateWallet, "Candidato ya propuesto");
        }
        
        positions[positionIndex].candidates.push(Candidate({
            wallet: candidateWallet,
            votes: 0
        }));
    }

    // Votar por un candidato
    function vote(uint256 positionIndex, address candidateWallet) public onlyShareholder {
        require(positionIndex < positions.length, "Posicion invalida");
        require(positions[positionIndex].electionOpen, "Eleccion no esta abierta para esta posicion");
        require(block.timestamp - positions[positionIndex].lastElectionTime <= VOTING_DURATION, "Periodo de votacion ha terminado");
        
        uint256 voteWeight = governanceToken.balanceOf(msg.sender);
        require(voteWeight > 0, "No tienes tokens para votar");
        
        bool candidateFound = false;
        for (uint256 i = 0; i < positions[positionIndex].candidates.length; i++) {
            if (positions[positionIndex].candidates[i].wallet == candidateWallet) {
                positions[positionIndex].candidates[i].votes += voteWeight;
                candidateFound = true;
                break;
            }
        }
        
        require(candidateFound, "Candidato no encontrado");
        emit VoteCast(msg.sender, positionIndex, candidateWallet, voteWeight);
    }

    // Finalizar elección y declarar ganadores
    function finalizeElection() public onlyShareholder {
        require(canFinalizeElection(), "No se puede finalizar la eleccion aun");
        
        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].candidates.length > 0) {
                address winner = positions[i].candidates[0].wallet;
                uint256 maxVotes = positions[i].candidates[0].votes;
                
                // Encontrar el candidato con más votos
                for (uint256 j = 1; j < positions[i].candidates.length; j++) {
                    if (positions[i].candidates[j].votes > maxVotes) {
                        maxVotes = positions[i].candidates[j].votes;
                        winner = positions[i].candidates[j].wallet;
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
        
        // Verificar que todas las elecciones estén abiertas
        for (uint256 i = 0; i < positions.length; i++) {
            if (!positions[i].electionOpen) {
                return false;
            }
        }
        
        // Verificar que ha pasado el tiempo de votación
        return (block.timestamp - positions[0].lastElectionTime) > VOTING_DURATION;
    }

    // Obtener información de candidatos para una posición
    function getCandidates(uint256 positionIndex) public view returns (Candidate[] memory) {
        require(positionIndex < positions.length, "Posicion invalida");
        return positions[positionIndex].candidates;
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
