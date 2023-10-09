// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkAssignableNFT.sol";

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkMultiAssignableNFT is IPatchworkAssignableNFT {
    // TODO getAssignmentCount? getAssignments paginated?

    function isAssignedTo(uint256 ourTokenId, address target, uint256 targetTokenId) external returns (bool);

    /**
    @notice Unassigns a token
    @param ourTokenId ID of our token
    */
    function unassign(uint256 ourTokenId, address target, uint256 targetTokenId) external;
}