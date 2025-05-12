// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/utils/structs/EnumerableSet.sol";

interface ISmartContractLand {
    function getOwnerByToken(uint256 tokenId) external view returns (address);
    function parcels(uint256) external view returns (
        uint256 tokenId,
        string memory coordinates,
        uint256 value,
        address currentOwner,
        uint8 landType,
        address leaseWallet,
        bool status
    );
}

contract StrategicGovernance is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    address public constant BT_AI_TOKEN = 0x01667E6fedBF020df3C51EB70Ab8420194332a8b;
    address public constant SMART_CONTRACT_LAND = 0xcD6a42782d230D7c13A74ddec5dD140e55499Df9;
    
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant QUORUM_PERCENTAGE = 51;
    uint256 public constant PARCEL_VOTE_WEIGHT = 1e15; // 0.001 token de peso por parcela
    uint256 public constant MIN_PROPOSAL_TOKENS = 1000000 * 1e18; // Mínimo para proponer
    
    enum ProposalType { STRATEGIC, OPERATIONAL, GOVERNANCE }
    enum ProposalStatus { ACTIVE, APPROVED, REJECTED }
    
    struct Proposal {
        uint256 id;
        ProposalType pType;
        string title;
        string description;
        string actaReference; // Referencia al acta física/digital
        uint256 creationDate;
        uint256 endDate;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        address proposer;
        mapping(address => bool) voted;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public parcelVotingPower;
    EnumerableSet.AddressSet private voters;
    
    event ProposalCreated(
        uint256 indexed id,
        ProposalType pType,
        address indexed proposer,
        string title,
        string actaReference
    );
    event Voted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );
    event ProposalResolved(
        uint256 indexed proposalId,
        ProposalStatus status
    );
    event VotingPowerUpdated(
        address indexed user,
        uint256 parcelCount,
        uint256 votingPower
    );

    function createProposal(
        ProposalType pType,
        string memory title,
        string memory description,
        string memory actaReference
    ) external {
        require(
            IERC20(BT_AI_TOKEN).balanceOf(msg.sender) >= MIN_PROPOSAL_TOKENS,
            "Insuficientes tokens para proponer"
        );
        
        uint256 proposalId = proposalCount++;
        Proposal storage p = proposals[proposalId];
        
        p.id = proposalId;
        p.pType = pType;
        p.title = title;
        p.description = description;
        p.actaReference = actaReference;
        p.creationDate = block.timestamp;
        p.endDate = block.timestamp + VOTING_PERIOD;
        p.proposer = msg.sender;
        p.status = ProposalStatus.ACTIVE;
        
        emit ProposalCreated(proposalId, pType, msg.sender, title, actaReference);
    }
    
    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(p.status == ProposalStatus.ACTIVE, "Votación no activa");
        require(block.timestamp <= p.endDate, "Periodo de votación terminado");
        require(!p.voted[msg.sender], "Ya votaste");
        
        uint256 voteWeight = getVotingWeight(msg.sender);
        require(voteWeight > 0, "No tienes poder de voto");
        
        p.voted[msg.sender] = true;
        voters.add(msg.sender);
        
        if (support) {
            p.yesVotes += voteWeight;
        } else {
            p.noVotes += voteWeight;
        }
        
        emit Voted(proposalId, msg.sender, support, voteWeight);
    }
    
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage p = proposals[proposalId];
        require(p.status == ProposalStatus.ACTIVE, "Propuesta ya resuelta");
        require(block.timestamp > p.endDate, "Votación en curso");
        
        uint256 totalVotes = p.yesVotes + p.noVotes;
        uint256 totalSupply = IERC20(BT_AI_TOKEN).totalSupply();
        
        if (totalVotes >= (totalSupply * QUORUM_PERCENTAGE) / 100) {
            p.status = p.yesVotes > p.noVotes ? 
                ProposalStatus.APPROVED : 
                ProposalStatus.REJECTED;
        } else {
            p.status = ProposalStatus.REJECTED;
        }
        
        emit ProposalResolved(proposalId, p.status);
    }
    
    function updateParcelVotingPower(address user) public {
        uint256 parcelCount = _getOwnedParcelsCount(user);
        uint256 newVotingPower = parcelCount * PARCEL_VOTE_WEIGHT;
        
        if (parcelVotingPower[user] != newVotingPower) {
            parcelVotingPower[user] = newVotingPower;
            emit VotingPowerUpdated(user, parcelCount, newVotingPower);
        }
    }
    
    function getVotingWeight(address user) public view returns (uint256) {
        return IERC20(BT_AI_TOKEN).balanceOf(user) + parcelVotingPower[user];
    }
    
    function getVoterDetails(address user) public view returns (
        uint256 tokenBalance,
        uint256 parcelsOwned,
        uint256 votingPower,
        bool canPropose
    ) {
        tokenBalance = IERC20(BT_AI_TOKEN).balanceOf(user);
        parcelsOwned = parcelVotingPower[user] / PARCEL_VOTE_WEIGHT;
        votingPower = getVotingWeight(user);
        canPropose = tokenBalance >= MIN_PROPOSAL_TOKENS;
    }
    
    function _getOwnedParcelsCount(address owner) internal view returns (uint256) {
        uint256 count = 0;
        // Implementación optimizada para producción necesitaría un mapeo de dueños
        for (uint256 i = 1; i <= 100; i++) { // Ajustar rango según necesidades
            (,,,address parcelOwner,,,,) = ISmartContractLand(SMART_CONTRACT_LAND).parcels(i);
            if (parcelOwner == owner) {
                count++;
            }
        }
        return count;
    }
}
