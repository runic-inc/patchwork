// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IPatchworkScoped.sol";

/**
@title Patchwork Protocol 1155 Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchwork1155Patch is IPatchworkScoped {
    /// @dev A canonical path to an 1155 patched target
    struct PatchTarget {
        address addr;    // The address of the 1155
        uint256 tokenId; // The tokenId of the 1155
        address account; // The account for the 1155
    }

    /**
    @notice Creates a new token for the owner, representing a patch
    @param to Address of the owner of the patch token
    @param target Path to an 1155 to patch
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address to, PatchTarget memory target) external payable returns (uint256 tokenId);

    // Add to Patchwork Protocol v2.1 interfaces
    // @notice Return the target patched by a tokenId 
    // @dev Not currently in IPatchwork1155Patch as this was added after Protocol v2 release
    // @param tokenId the ID of the token
    // @return PatchTarget the target patched by the tokenId
    //
    // function getTarget(uint256 tokenId) external view returns (PatchTarget memory);
}

/**
@title Patchwork Protocol Reversible 1155 Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard with reverse lookup
*/
interface IPatchworkReversible1155Patch is IPatchwork1155Patch {
    /**
    @notice Returns the token ID (if it exists) for an 1155 that may have been patched
    @dev Requires reverse storage enabled
    @param target The 1155 target that was patched
    @return tokenId token ID of the patch
    */
    function getTokenIdByTarget(PatchTarget memory target) external returns (uint256 tokenId);
}