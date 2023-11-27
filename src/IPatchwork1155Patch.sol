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
    function getScopeName() external view returns (string memory);

    /**
    @notice Creates a new token for the owner, representing a patch
    @param to Address of the owner of the patch token
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId ID of the original NFT token
    @param originalAccount Address of the original 1155 account
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address to, address originalNFTAddress, uint256 originalNFTTokenId, address originalAccount) external returns (uint256 tokenId);

    /**
    @notice Returns the token ID (if it exists) for an NFT that may have been patched
    @dev Requires reverse storage enabled
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId ID of the original NFT token
    @param originalAccount Address of the original 1155 account
    @return tokenId ID of the newly minted token
    */
    function getTokenIdForOriginalNFT(address originalNFTAddress, uint256 originalNFTTokenId, address originalAccount) external returns (uint256 tokenId);
}