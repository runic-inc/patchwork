// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkAssignableNFT.sol";

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkMultiAssignableNFT is IPatchworkAssignableNFT {

    struct Assignment {
        address tokenAddr;  /// The address of the external NFT contract.
        uint256 tokenId;    /// The ID of the token in the external NFT contract.
    }

    /**
    @notice Checks if this fragment is assigned to a target
    @param ourTokenId the tokenId of the fragment
    @param target the address of the target
    @param targetTokenId the tokenId of the target
    */
    function isAssignedTo(uint256 ourTokenId, address target, uint256 targetTokenId) external returns (bool);

    /**
    @notice Unassigns a token
    @param ourTokenId tokenId of our fragment
    */
    function unassign(uint256 ourTokenId, address target, uint256 targetTokenId) external;

    /**
    @notice Counts the number of unique assignments this token has
    @param tokenId tokenId of our fragment
    */
    function getAssignmentCount(uint256 tokenId) external returns (uint256);

    /**
    @notice Gets assignments for a fragment
    @param tokenId tokenId of our fragment
    @param offset the page offset
    @param count the maximum numer of entries to return
    */
    function getAssignments(uint256 tokenId, uint256 offset, uint256 count) external returns (Assignment[] memory);

    /**
    @notice Checks permissions for assignment
    @param ourTokenId the tokenID to assign
    @param to the address to assign to
    @param toTokenId the tokenID to assign to
    @param scopeName the scope name of the contract to assign to
    */
    function allowAssignment(uint256 ourTokenId, address to, uint256 toTokenId, string memory scopeName) external returns (bool);
}