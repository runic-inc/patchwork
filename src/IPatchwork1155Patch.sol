// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkScoped.sol";

/**
@title Patchwork Protocol 1155 Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchwork1155Patch is IPatchworkScoped {
    /**
    @notice Creates a new token for the owner, representing a patch
    @param to Address of the owner of the patch token
    @param originalAddress Address of the original 1155
    @param originalTokenId ID of the original 1155 token
    @param originalAccount Address of the original 1155 account
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address to, address originalAddress, uint256 originalTokenId, address originalAccount) external returns (uint256 tokenId);
}

/**
@title Patchwork Protocol Reversible 1155 Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard with reverse lookup
*/
interface IPatchworkReversible1155Patch is IPatchwork1155Patch {
    /**
    @notice Returns the token ID (if it exists) for an NFT that may have been patched
    @dev Requires reverse storage enabled
    @param originalAddress Address of the original 1155
    @param originalTokenId ID of the original 1155 token
    @param originalAccount Address of the original 1155 account
    @return tokenId ID of the newly minted token
    */
    function getTokenIdForOriginal1155(address originalAddress, uint256 originalTokenId, address originalAccount) external returns (uint256 tokenId);
}