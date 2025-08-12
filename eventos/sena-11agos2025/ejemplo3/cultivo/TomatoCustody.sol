// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC721/IERC721.sol";

contract TomatoCustody is Ownable {
    IERC721 public immutable nft;

    struct Listing {
        address seller;
        uint256 priceWei; // precio en ETH (wei)
        bool active;
    }

    // tokenId => listing
    mapping(uint256 => Listing) public listings;

    event Deposited(uint256 indexed tokenId, address indexed from);
    event Listed(uint256 indexed tokenId, uint256 priceWei);
    event Delisted(uint256 indexed tokenId);
    event Purchased(uint256 indexed tokenId, address indexed buyer, uint256 priceWei);
    event Withdrawn(uint256 indexed tokenId, address indexed to);

    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
    }

    // 1) Depositar NFT en custodia (el owner debe hacer approve primero a este contrato)
    function deposit(uint256 tokenId) external {
        nft.transferFrom(msg.sender, address(this), tokenId);
        emit Deposited(tokenId, msg.sender);
    }

    // 2) Listar en venta (sólo el dueño anterior o el owner del contrato; simple)
    function list(uint256 tokenId, uint256 priceWei) external {
        require(nft.ownerOf(tokenId) == address(this), "not in custody");
        Listing storage L = listings[tokenId];
        require(L.seller == address(0) || L.seller == msg.sender || owner() == msg.sender, "not seller");
        listings[tokenId] = Listing({ seller: msg.sender, priceWei: priceWei, active: true });
        emit Listed(tokenId, priceWei);
    }

    // 3) Deslistar
    function delist(uint256 tokenId) external {
        Listing storage L = listings[tokenId];
        require(L.active, "not listed");
        require(L.seller == msg.sender || owner() == msg.sender, "not seller");
        L.active = false;
        emit Delisted(tokenId);
    }

    // 4) Comprar (paga en ETH)
    function buy(uint256 tokenId) external payable {
        Listing storage L = listings[tokenId];
        require(L.active, "not listed");
        require(msg.value == L.priceWei, "bad price");
        address seller = L.seller;
        L.active = false;

        // pagar primero
        (bool ok, ) = seller.call{value: msg.value}("");
        require(ok, "pay fail");

        // transferir NFT
        nft.transferFrom(address(this), msg.sender, tokenId);

        emit Purchased(tokenId, msg.sender, msg.value);
    }

    // 5) Retirar NFT sin vender (sólo el vendedor original o el owner)
    function withdraw(uint256 tokenId, address to) external {
        Listing storage L = listings[tokenId];
        require(nft.ownerOf(tokenId) == address(this), "not in custody");
        require(L.seller == msg.sender || owner() == msg.sender, "not seller");
        L.active = false;
        nft.transferFrom(address(this), to, tokenId);
        emit Withdrawn(tokenId, to);
    }
}
