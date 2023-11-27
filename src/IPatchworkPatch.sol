// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
@title Patchwork Protocol Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchworkPatch {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external view returns (string memory);

    /**
    @notice Creates a new token for the owner, representing a patch
    @param owner Address of the owner of the token
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId ID of the original NFT token
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address owner, address originalNFTAddress, uint256 originalNFTTokenId) external returns (uint256 tokenId);

    /**
    @notice Updates the real underlying ownership of a token in storage (if different from current)
    @param tokenId ID of the token
    */
    function updateOwnership(uint256 tokenId) external;

    /**
    @notice Returns the underlying stored owner of a token ignoring real patched NFT ownership
    @param tokenId ID of the token
    @return address Address of the owner
    */
    function unpatchedOwnerOf(uint256 tokenId) external view returns (address);

    /**
    @notice Returns the token ID (if it exists) for an NFT that may have been patched
    @dev Requires reverse storage enabled
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId ID of the original NFT token
    @return tokenId ID of the newly minted token
    */
    function getTokenIdForOriginalNFT(address originalNFTAddress, uint256 originalNFTTokenId) external view returns (uint256 tokenId);
}