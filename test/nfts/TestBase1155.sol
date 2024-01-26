// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract TestBase1155 is ERC1155 {

    constructor() ERC1155("http://myurl/") {
    }

    function mint(address to, uint256 tokenId, uint256 amount) public returns (uint256) {
        _mint(to, tokenId, amount, "");
        return tokenId;
    }
}