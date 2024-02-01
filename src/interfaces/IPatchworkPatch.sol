// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IPatchworkScoped.sol";

/**
@title Patchwork Protocol Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchworkPatch is IPatchworkScoped {
    /// @dev A canonical path to an 721 patched
    struct PatchTarget {
        address addr;    // The address of the 721
        uint256 tokenId; // The tokenId of the 721
    }
    
    /**
    @notice Creates a new token for the owner, representing a patch
    @param owner Address of the owner of the token
    @param target path to target of patch
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address owner, PatchTarget memory target) external payable returns (uint256 tokenId);

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
    function ownerOfPatch(uint256 tokenId) external view returns (address);
}

/**
@title Patchwork Protocol Reversible Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard with reverse lookup
*/
interface IPatchworkReversiblePatch is IPatchworkPatch {
    /**
    @notice Returns the token ID (if it exists) for an NFT that may have been patched
    @dev Requires reverse storage enabled
    @param target Patch to target of patch
    @return tokenId token ID of the patch
    */
    function getTokenIdByTarget(PatchTarget memory target) external view returns (uint256 tokenId);
}