// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
@title Patchwork Protocol Account Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchworkAccountPatch {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external view returns (string memory);

    /**
    @notice Creates a new token for the owner, representing a patch
    @param owner Address of the owner of the token
    @param originalAccountAddress Address of the original account
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address owner, address originalAccountAddress) external returns (uint256 tokenId);

    /**
    @notice Returns the token ID (if it exists) for an NFT that may have been patched
    @dev Requires reverse storage enabled
    @param originalAddress Address of the original account
    @return tokenId ID of the newly minted token
    */
    function getTokenIdForOriginalAccount(address originalAddress) external returns (uint256 tokenId);
}