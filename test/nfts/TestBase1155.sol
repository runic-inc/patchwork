// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract TestBase1155 is ERC1155 {
    uint256 public tokenId;

    constructor() ERC1155("http://myurl/") {
    }

    function mint(address to, uint256 quantity) public returns (uint256) {
        uint256 newTokenId = tokenId;
        tokenId++;
        _mint(to, newTokenId, quantity, "");
        return newTokenId;
    }
}