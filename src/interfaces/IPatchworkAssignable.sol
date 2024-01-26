// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IPatchworkScoped.sol";

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkAssignable is IPatchworkScoped {
    
    /// Represents an assignment of a token from an external NFT contract to a token in this contract.
    struct Assignment {
        address tokenAddr;  /// The address of the external NFT contract.
        uint256 tokenId;    /// The ID of the token in the external NFT contract.
    }

    /**
    @notice Assigns a token to another
    @param ourTokenId ID of our token
    @param to Address to assign to
    @param tokenId ID of the token to assign
    */
    function assign(uint256 ourTokenId, address to, uint256 tokenId) external;

    /**
    @notice Checks permissions for assignment
    @param ourTokenId the tokenID to assign
    @param target the address of the target
    @param targetTokenId the tokenID of the target
    @param targetOwner the ownerOf of the target
    @param by the account invoking the assignment to Patchwork Protocol
    @param scopeName the scope name of the contract to assign to
    */
    function allowAssignment(uint256 ourTokenId, address target, uint256 targetTokenId, address targetOwner, address by, string memory scopeName) external view returns (bool);
}