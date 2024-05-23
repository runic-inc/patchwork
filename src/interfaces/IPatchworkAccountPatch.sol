// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IPatchworkScoped.sol";

/**
@title Patchwork Protocol Account Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchworkAccountPatch is IPatchworkScoped {
    /**
    @notice Creates a new token for the owner, representing a patch
    @param owner Address of the owner of the token
    @param target Address of the original account
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address owner, address target) external payable returns (uint256 tokenId);

    // Add to Patchwork Protocol v2.1 interfaces
    // @notice Return the account patched by a tokenId 
    // @dev Not currently in IPatchworkPatch as this was added after Protocol v2 release
    // @param tokenId the ID of the token
    // @return account the account patched by the tokenId
    //
    // function getTarget(uint256 tokenId) external view returns (address account);
}

/**
@title Patchwork Protocol Reversible Account Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork account patch standard with reverse lookup
*/
interface IPatchworkReversibleAccountPatch is IPatchworkAccountPatch {
    /**
    @notice Returns the token ID (if it exists) for an NFT that may have been patched
    @dev Requires reverse storage enabled
    @param target Address of the original account
    @return tokenId ID of the newly minted token
    */
    function getTokenIdByTarget(address target) external returns (uint256 tokenId);
}