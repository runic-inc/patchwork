// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IPatchworkScoped.sol";

/**
@title Patchwork Mintable Interface
@author Runic Labs, Inc
*/
interface IPatchworkMintable is IPatchworkScoped {

    /**
    @notice Mint a new token
    @dev Mints a single token to a specified address.
    @param to The address to which the token will be minted.
    @param data Additional data to be passed to the minting process.
    @return tokenId The ID of the minted token.
    */
    function mint(address to, bytes calldata data) external payable returns (uint256 tokenId);
    
    /**
    @notice Mint a batch of new tokens
    @dev Mints multiple tokens to a specified address.
    @param to The address to which the tokens will be minted.
    @param data Additional data to be passed to the minting process.
    @param quantity The number of tokens to mint.
    @return tokenIds An array of the IDs of the minted tokens.
    */
    function mintBatch(address to, bytes calldata data, uint256 quantity) external payable returns (uint256[] memory tokenIds);
}