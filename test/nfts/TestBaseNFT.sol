// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract TestBaseNFT is ERC721 {
    uint256 public tokenId;

    constructor() ERC721("TestBase", "TEST") {
    }

    function mint(address to) public returns (uint256) {
        uint256 newTokenId = tokenId;
        tokenId++;
        _safeMint(to, newTokenId);
        return newTokenId;
    }
}