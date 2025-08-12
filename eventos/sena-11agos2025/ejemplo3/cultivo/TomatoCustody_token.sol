// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC20/utils/SafeERC20.sol";

contract TomatoCustodyERC20 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC721 public immutable nft;
    IERC20  public immutable payToken; // token de pago (por ej. USDC, DAI, etc.)

    struct Listing {
        address seller;       // depositante
        uint256 price;        // precio en unidades mínimas del token (decimals)
        bool    active;
        address reservedFor;  // 0x0 = cualquiera
        uint64  deadline;     // 0 = sin vencimiento (timestamp)
    }

    // tokenId => depositante
    mapping(uint256 => address) public depositor;
    // tokenId => listing
    mapping(uint256 => Listing) public listings;

    event Deposited(uint256 indexed tokenId, address indexed from);
    event Listed(uint256 indexed tokenId, uint256 price, address reservedFor, uint64 deadline);
    event Delisted(uint256 indexed tokenId);
    event Purchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event Withdrawn(uint256 indexed tokenId, address indexed to);

    constructor(address nftAddress, address payTokenAddress) {
        require(nftAddress != address(0) && payTokenAddress != address(0), "zero addr");
        nft = IERC721(nftAddress);
        payToken = IERC20(payTokenAddress);
    }

    // 1) Depositar NFT en custodia (hacer approve primero a este contrato)
    function deposit(uint256 tokenId) external nonReentrant {
        nft.transferFrom(msg.sender, address(this), tokenId);
        depositor[tokenId] = msg.sender;
        // invalida cualquier lista previa
        listings[tokenId].active = false;
        emit Deposited(tokenId, msg.sender);
    }

    // 2a) Listar venta abierta
    function list(uint256 tokenId, uint256 price) external {
        _list(tokenId, price, address(0), 0);
    }

    // 2b) Listar reservado para alguien (con deadline opcional)
    function listFor(uint256 tokenId, uint256 price, address reservedFor, uint64 deadline) external {
        _list(tokenId, price, reservedFor, deadline);
    }

    function _list(uint256 tokenId, uint256 price, address reservedFor, uint64 deadline) internal {
        require(nft.ownerOf(tokenId) == address(this), "not in custody");
        address dep = depositor[tokenId];
        require(dep == msg.sender || owner() == msg.sender, "not depositor");
        require(price > 0, "price=0");

        listings[tokenId] = Listing({
            seller: dep == address(0) ? msg.sender : dep, // si minteaste directo a custodia
            price: price,
            active: true,
            reservedFor: reservedFor,
            deadline: deadline
        });
        emit Listed(tokenId, price, reservedFor, deadline);
    }

    // 3) Deslistar
    function delist(uint256 tokenId) external {
        Listing storage L = listings[tokenId];
        require(L.active, "not listed");
        require(depositor[tokenId] == msg.sender || owner() == msg.sender, "not depositor");
        L.active = false;
        emit Delisted(tokenId);
    }

    // 4) Comprar (paga con ERC-20 especificado)
    function buy(uint256 tokenId) external nonReentrant {
        Listing storage L = listings[tokenId];
        require(L.active, "not listed");
        require(nft.ownerOf(tokenId) == address(this), "not in custody");
        if (L.reservedFor != address(0)) require(msg.sender == L.reservedFor, "not allowed buyer");
        if (L.deadline != 0) require(block.timestamp <= L.deadline, "expired");

        // Cobro en token: buyer -> seller
        payToken.safeTransferFrom(msg.sender, L.seller, L.price);

        // Cerrar listing y limpiar depositante
        L.active = false;
        depositor[tokenId] = address(0);

        // Transferir NFT a buyer
        nft.transferFrom(address(this), msg.sender, tokenId);

        emit Purchased(tokenId, msg.sender, L.price);
    }

    // 5) Retirar NFT sin vender (depositante u owner)
    function withdraw(uint256 tokenId, address to) external nonReentrant {
        require(nft.ownerOf(tokenId) == address(this), "not in custody");
        require(depositor[tokenId] == msg.sender || owner() == msg.sender, "not depositor");
        listings[tokenId].active = false;
        depositor[tokenId] = address(0);
        nft.transferFrom(address(this), to, tokenId);
        emit Withdrawn(tokenId, to);
    }
}
