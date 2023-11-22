// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
@title Patchwork Mintable Interface
@author Runic Labs, Inc
*/
interface IPatchworkMintable {
    function getScopeName() external returns (string memory scopeName);
    
    function mint(address to, bytes calldata data) external returns (uint256 tokenId);
    
    function mintBatch(address to, bytes calldata data, uint256 quantity) external returns (uint256[] memory tokenIds);
}