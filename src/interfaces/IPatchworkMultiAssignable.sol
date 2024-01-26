// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IPatchworkAssignable.sol";

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkMultiAssignable is IPatchworkAssignable {

    /**
    @notice Checks if this fragment is assigned to a target
    @param ourTokenId the tokenId of the fragment
    @param target the address of the target
    @param targetTokenId the tokenId of the target
    */
    function isAssignedTo(uint256 ourTokenId, address target, uint256 targetTokenId) external view returns (bool);

    /**
    @notice Unassigns a token
    @param ourTokenId tokenId of our fragment
    */
    function unassign(uint256 ourTokenId, address target, uint256 targetTokenId) external;

    /**
    @notice Counts the number of unique assignments this token has
    @param tokenId tokenId of our fragment
    */
    function getAssignmentCount(uint256 tokenId) external view returns (uint256);

    /**
    @notice Gets assignments for a fragment
    @param tokenId tokenId of our fragment
    @param offset the page offset
    @param count the maximum numer of entries to return
    */
    function getAssignments(uint256 tokenId, uint256 offset, uint256 count) external view returns (Assignment[] memory);
}