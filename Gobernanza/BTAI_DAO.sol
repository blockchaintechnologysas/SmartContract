// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Importaciones directas desde GitHub (v4.9.0)
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/utils/structs/EnumerableSet.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/IERC20.sol";

/**
 * @title BT&AI Share Registry - Libro de Accionistas Digital
 */
contract BTAI_ShareRegistry is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct Shareholder {
        address wallet;
        uint256 shares;
        uint256 entryDate;
        bool isActive;
    }

    struct TransferRecord {
        address from;
        address to;
        uint256 amount;
        uint256 date;
        string observation;
    }

    uint8 private constant _decimals = 2;
    uint256 private constant TOTAL_SHARES = 100_000_000_000 * 10 ** _decimals;
    
    mapping(address => Shareholder) public shareholders;
    TransferRecord[] public transferHistory;
    EnumerableSet.AddressSet private shareholderAddresses;
    bool public isActive = true;

    string public constant LEGAL_NAME = "BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI S.A.S";
    string public constant TAX_ID = "901676524-7";
    string public constant ADDRESS = "Carrera 14 A #25-06, Calima, Valle del Cauca";
    string public constant REGISTRATION = "Matricula No: 83800";

    event SharesTransferred(address indexed from, address indexed to, uint256 amount, string observation);
    event SuccessionExecuted(address indexed deceased, address[] heirs, uint256[] amounts, string legalDocument);
    event ShareholderRegistered(address indexed shareholder, uint256 shares, uint256 date);
    event ContractMigrated(address indexed newContract, uint256 totalSharesMigrated, uint256 migrationDate);

    constructor() ERC20("BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI", "BT&AI") {
        _mint(msg.sender, TOTAL_SHARES);
        _registerShareholder(msg.sender, TOTAL_SHARES);
    }

    modifier onlyActive() {
        require(isActive, "Contract is inactive - migration completed");
        _;
    }

    function transfer(address to, uint256 amount) public override onlyActive returns (bool) {
        require(balanceOf(msg.sender) >= amount, "Insufficient shares");
        
        _transfer(msg.sender, to, amount);
        _recordTransfer(msg.sender, to, amount, "Transferencia voluntaria");
        _updateShareholder(msg.sender, balanceOf(msg.sender));
        _updateShareholder(to, balanceOf(to));
        
        return true;
    }

    function executeSuccession(
        address deceased, 
        address[] memory heirs, 
        uint256[] memory amounts,
        string memory legalDocument
    ) public onlyOwner onlyActive {
        require(heirs.length == amounts.length, "Arrays length mismatch");
        
        uint256 total;
        for (uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        
        require(balanceOf(deceased) >= total, "Insufficient shares");
        
        for (uint i = 0; i < heirs.length; i++) {
            _transfer(deceased, heirs[i], amounts[i]);
            _recordTransfer(deceased, heirs[i], amounts[i], 
                string(abi.encodePacked("Sucesion. Doc: ", legalDocument)));
            _updateShareholder(heirs[i], balanceOf(heirs[i]));
        }
        
        _updateShareholder(deceased, balanceOf(deceased));
        emit SuccessionExecuted(deceased, heirs, amounts, legalDocument);
    }

    function migrateContract(address newContractAddress) public onlyOwner {
        require(isActive, "Contract already migrated");
        isActive = false;
        
        uint256 totalMigrated = 0;
        address[] memory shareholdersList = shareholderAddresses.values();
        
        for (uint i = 0; i < shareholdersList.length; i++) {
            address shareholder = shareholdersList[i];
            uint256 balance = balanceOf(shareholder);
            
            if (balance > 0 && shareholder != owner()) {
                _transfer(shareholder, owner(), balance);
                totalMigrated += balance;
                
                _recordTransfer(
                    shareholder, 
                    owner(), 
                    balance, 
                    string(abi.encodePacked("Migracion a nuevo contrato: ", _addressToString(newContractAddress)))
                );
                
                _updateShareholder(shareholder, 0);
            }
        }
        
        if (newContractAddress != address(0)) {
            uint256 ownerBalance = balanceOf(owner());
            _transfer(owner(), newContractAddress, ownerBalance);
            totalMigrated += ownerBalance;
            
            _recordTransfer(
                owner(), 
                newContractAddress, 
                ownerBalance, 
                "Migracion final a nuevo contrato"
            );
        }
        
        emit ContractMigrated(newContractAddress, totalMigrated, block.timestamp);
    }

    function getTransferHistory() public view returns (TransferRecord[] memory) {
        return transferHistory;
    }

    function getShareholderList() public view returns (Shareholder[] memory) {
        Shareholder[] memory list = new Shareholder[](shareholderAddresses.length());
        for (uint i = 0; i < shareholderAddresses.length(); i++) {
            list[i] = shareholders[shareholderAddresses.at(i)];
        }
        return list;
    }

    function _registerShareholder(address wallet, uint256 shares) internal {
        shareholders[wallet] = Shareholder({
            wallet: wallet,
            shares: shares,
            entryDate: block.timestamp,
            isActive: true
        });
        shareholderAddresses.add(wallet);
        emit ShareholderRegistered(wallet, shares, block.timestamp);
    }

    function _updateShareholder(address wallet, uint256 newBalance) internal {
        if (newBalance > 0) {
            shareholders[wallet].shares = newBalance;
            if (!shareholderAddresses.contains(wallet)) {
                _registerShareholder(wallet, newBalance);
            }
        } else {
            shareholders[wallet].isActive = false;
            shareholderAddresses.remove(wallet);
        }
    }

    function _recordTransfer(address from, address to, uint256 amount, string memory observation) internal {
        transferHistory.push(TransferRecord({
            from: from,
            to: to,
            amount: amount,
            date: block.timestamp,
            observation: observation
        }));
        emit SharesTransferred(from, to, amount, observation);
    }

    function _addressToString(address _addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}

/**
 * @title BT&AI DAO Governance
 */
contract BTAI_DAO is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    BTAI_ShareRegistry public shareRegistry;
    
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
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    BoardPosition[] public boardPositions;
    Candidate[] public candidates;
    EnumerableSet.AddressSet private topShareholders;
    
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant BOARD_TERM = 730 days;
    uint256 public constant QUORUM_PERCENTAGE = 51;
    uint256 public constant TOP_SHAREHOLDERS_COUNT = 10;
    
    event ProposalCreated(uint256 id, ProposalType pType, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalResolved(uint256 proposalId, bool approved);
    event BoardElected(string position, address elected, uint256 endTerm);
    event CandidateNominated(address candidate, string position);
    event VoteCasted(address voter, address candidate, string position, uint256 weight);

    constructor(address _shareRegistry) {
        shareRegistry = BTAI_ShareRegistry(_shareRegistry);
        _initializeBoardPositions();
        _updateTopShareholders();
    }

    function createProposal(
        ProposalType pType,
        string memory description,
        address tokenAddress,
        address targetAddress,
        uint256 amount
    ) public {
        require(isTopShareholder(msg.sender), "Only top shareholders can propose");
        require(shareRegistry.isActive(), "Registry contract is not active");
        
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
            require(tokenAddress != address(0), "Token address required");
            p.tokenAddress = tokenAddress;
            p.targetAddress = targetAddress;
            p.amount = amount;
        }
        
        emit ProposalCreated(proposalId, pType, msg.sender, description);
    }
    
    function vote(uint256 proposalId, bool support) public {
        Proposal storage p = proposals[proposalId];
        require(p.status == ProposalStatus.ACTIVE, "Voting not active");
        require(block.timestamp <= p.endDate, "Voting period ended");
        require(!p.votes[msg.sender], "Already voted");
        require(shareRegistry.balanceOf(msg.sender) > 0, "No shares to vote");
        
        uint256 weight = shareRegistry.balanceOf(msg.sender);
        p.votes[msg.sender] = true;
        
        if (support) {
            p.yesVotes += weight;
        } else {
            p.noVotes += weight;
        }
        
        emit Voted(proposalId, msg.sender, support, weight);
        _checkVoting(proposalId);
    }
    
    function executeProposal(uint256 proposalId) public {
        Proposal storage p = proposals[proposalId];
        require(p.status == ProposalStatus.APPROVED, "Proposal not approved");
        require(p.pType == ProposalType.ECONOMIC, "Only economic proposals can be executed");
        
        if (p.tokenAddress == address(shareRegistry)) {
            IERC20(p.tokenAddress).transfer(p.targetAddress, p.amount);
        } else {
            revert("External token execution not yet implemented");
        }
        
        p.status = ProposalStatus.EXECUTED;
    }
    
    function nominateCandidate(address candidate, string memory position) public {
        require(isTopShareholder(msg.sender), "Only top shareholders can nominate");
        require(_isValidPosition(position), "Invalid board position");
        require(shareRegistry.balanceOf(candidate) > 0, "Candidate must be a shareholder");
        
        candidates.push(Candidate({
            candidateAddress: candidate,
            position: position,
            votesReceived: 0
        }));
        
        emit CandidateNominated(candidate, position);
    }
    
    function voteForCandidate(address candidate, string memory position) public {
        require(shareRegistry.balanceOf(msg.sender) > 0, "No shares to vote");
        
        uint256 weight = shareRegistry.balanceOf(msg.sender);
        bool found = false;
        
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].candidateAddress == candidate && 
                keccak256(bytes(candidates[i].position)) == keccak256(bytes(position))) {
                candidates[i].votesReceived += weight;
                found = true;
                break;
            }
        }
        
        require(found, "Candidate not found for position");
        emit VoteCasted(msg.sender, candidate, position, weight);
    }
    
    function conductElections() public onlyOwner {
        require(block.timestamp >= boardPositions[0].nextElection, "Elections not yet due");
        
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
    
    function isTopShareholder(address shareholder) public view returns (bool) {
        return topShareholders.contains(shareholder);
    }
    
    function updateTopShareholders() public {
        _updateTopShareholders();
    }
    
    function getBoardPositions() public view returns (BoardPosition[] memory) {
        return boardPositions;
    }
    
    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
    
    function _initializeBoardPositions() internal {
        boardPositions.push(BoardPosition("Presidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Vicepresidente", address(0), 0, 0));
        boardPositions.push(BoardPosition("Secretario", address(0), 0, 0));
        boardPositions.push(BoardPosition("Fiscal", address(0), 0, 0));
        boardPositions.push(BoardPosition("Tesorero", address(0), 0, 0));
        boardPositions.push(BoardPosition("CEO", address(0), 0, 0));
    }
    
    function _updateTopShareholders() internal {
        delete topShareholders;
        
        BTAI_ShareRegistry.Shareholder[] memory shareholders = shareRegistry.getShareholderList();
        
        for (uint i = 0; i < shareholders.length && i < TOP_SHAREHOLDERS_COUNT; i++) {
            topShareholders.add(shareholders[i].wallet);
        }
    }
    
    function _checkVoting(uint256 proposalId) internal {
        Proposal storage p = proposals[proposalId];
        
        if (block.timestamp >= p.endDate) {
            uint256 totalVotes = p.yesVotes + p.noVotes;
            uint256 totalSupply = shareRegistry.totalSupply();
            
            if (p.pType == ProposalType.BOARD_ELECTION) {
                p.status = p.yesVotes > p.noVotes ? ProposalStatus.APPROVED : ProposalStatus.REJECTED;
            } else {
                if (totalVotes * 100 >= totalSupply * QUORUM_PERCENTAGE) {
                    p.status = p.yesVotes > p.noVotes ? ProposalStatus.APPROVED : ProposalStatus.REJECTED;
                } else {
                    p.status = ProposalStatus.REJECTED;
                }
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
