// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
@title Patchwork Protocol 1155 Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchwork1155Patch {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Creates a new token for the owner, representing a patch
    @param to Address of the owner of the patch token
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId ID of the original NFT token
    @param owner Address of the 1155 owner
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address to, address originalNFTAddress, uint256 originalNFTTokenId, address owner) external returns (uint256 tokenId);
}