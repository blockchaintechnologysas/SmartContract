// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/utils/Counters.sol";

contract TomatoNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _ids;

    event Minted(uint256 indexed tokenId, address indexed to);

    constructor() ERC721("TomatoTraceNFT", "TTN") {}

    // Acuña N NFTs y los deja en el dueño del contrato (o en la custodia si prefieres)
    function mintBatch(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "amount=0");
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = _ids.current();
            _safeMint(to, id);
            _ids.increment();
            emit Minted(id, to);
        }
    }

    function nextId() external view returns (uint256) {
        return _ids.current();
    }
}
