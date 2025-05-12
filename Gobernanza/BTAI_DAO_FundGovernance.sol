// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/utils/SafeERC20.sol";

interface ISmartContractLand {
    function getOwnerByToken(uint256 tokenId) external view returns (address);
    function getLeaseWallet(uint256 tokenId) external view returns (address);
    function parcels(uint256) external view returns (
        uint256 tokenId,
        string memory coordinates,
        uint256 value,
        address currentOwner,
        uint8 landType, // Enum is represented as uint8
        address leaseWallet,
        bool status
    );
}

contract FundGovernance is Ownable {
    using SafeERC20 for IERC20;
    
    address public constant BT_AI_TOKEN = 0x01667E6fedBF020df3C51EB70Ab8420194332a8b;
    address public constant SMART_CONTRACT_LAND = 0xcD6a42782d230D7c13A74ddec5dD140e55499Df9;
    
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant QUORUM_PERCENTAGE = 51;
    uint256 public constant PARCEL_VOTE_WEIGHT = 1e15; // 0.001 token de peso por parcela
    
    struct FundProposal {
        uint256 id;
        address token;
        address recipient;
        uint256 amount;
        string description;
        uint256 endDate;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) voted;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => FundProposal) public proposals;
    mapping(address => uint256) public parcelVotingPower; // Poder de voto por parcelas
    
    event FundProposalCreated(uint256 id, address token, address recipient, uint256 amount, string description);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 proposalId);
    event VotingPowerUpdated(address user, uint256 parcelCount, uint256 votingPower);

    function createProposal(
        address token,
        address recipient,
        uint256 amount,
        string memory description
    ) public {
        require(hasVotingPower(msg.sender), "Debes tener tokens o parcelas para proponer");
        
        uint256 proposalId = proposalCount++;
        FundProposal storage p = proposals[proposalId];
        
        p.id = proposalId;
        p.token = token;
        p.recipient = recipient;
        p.amount = amount;
        p.description = description;
        p.endDate = block.timestamp + VOTING_PERIOD;
        
        emit FundProposalCreated(proposalId, token, recipient, amount, description);
    }
    
    function vote(uint256 proposalId, bool support) public {
        FundProposal storage p = proposals[proposalId];
        require(hasVotingPower(msg.sender), "No tienes derechos para votar");
        require(block.timestamp <= p.endDate, "Periodo de votacion terminado");
        require(!p.voted[msg.sender], "Ya votaste");
        
        uint256 voteWeight = getVotingWeight(msg.sender);
        p.voted[msg.sender] = true;
        
        if (support) {
            p.yesVotes += voteWeight;
        } else {
            p.noVotes += voteWeight;
        }
        
        emit Voted(proposalId, msg.sender, support, voteWeight);
    }
    
    function executeProposal(uint256 proposalId) public onlyOwner {
        FundProposal storage p = proposals[proposalId];
        require(block.timestamp > p.endDate, "Votacion en curso");
        require(!p.executed, "Propuesta ya ejecutada");
        
        uint256 totalVotes = p.yesVotes + p.noVotes;
        uint256 totalSupply = IERC20(BT_AI_TOKEN).totalSupply();
        
        require(totalVotes >= (totalSupply * QUORUM_PERCENTAGE) / 100, "No se alcanzo el quorum");
        
        if (p.yesVotes > p.noVotes) {
            IERC20(p.token).safeTransfer(p.recipient, p.amount);
            p.executed = true;
            emit ProposalExecuted(proposalId);
        }
    }
    
    // Funciones para manejar el poder de voto de parcelas
    
    function updateParcelVotingPower(address user) public {
        uint256 parcelCount = _getOwnedParcelsCount(user);
        uint256 newVotingPower = parcelCount * PARCEL_VOTE_WEIGHT;
        
        if (parcelVotingPower[user] != newVotingPower) {
            parcelVotingPower[user] = newVotingPower;
            emit VotingPowerUpdated(user, parcelCount, newVotingPower);
        }
    }
    
    // Funciones de consulta
    
    function hasVotingPower(address user) public view returns (bool) {
        return IERC20(BT_AI_TOKEN).balanceOf(user) > 0 || parcelVotingPower[user] > 0;
    }
    
    function getVotingWeight(address user) public view returns (uint256) {
        return IERC20(BT_AI_TOKEN).balanceOf(user) + parcelVotingPower[user];
    }
    
    function getParcelVotingInfo(address user) public view returns (uint256 parcelsOwned, uint256 votingPower) {
        parcelsOwned = parcelVotingPower[user] / PARCEL_VOTE_WEIGHT;
        votingPower = parcelVotingPower[user];
    }
    
    // Funciones internas
    
    function _getOwnedParcelsCount(address owner) internal view returns (uint256) {
        // Implementación simplificada - en producción necesitarías iterar todas las parcelas
        // o mantener un registro separado de dueños
        uint256 count = 0;
        
        // Ejemplo: verificar las primeras 100 parcelas (ajustar según necesidades)
        for (uint256 i = 1; i <= 100; i++) {
            (,,,address parcelOwner,,,,) = ISmartContractLand(SMART_CONTRACT_LAND).parcels(i);
            if (parcelOwner == owner) {
                count++;
            }
        }
        
        return count;
    }
}
