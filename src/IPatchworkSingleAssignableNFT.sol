// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkAssignableNFT.sol";

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkSingleAssignableNFT is IPatchworkAssignableNFT {
    /**
    @notice Returns the address and token ID that our token is assigned to
    @param ourTokenId ID of our token
    @return address the address this is assigned to
    @return uint256 the tokenId this is assigned to
    */
    function getAssignedTo(uint256 ourTokenId) external view returns (address, uint256);

    /**
    @notice Returns the underlying stored owner of a token ignoring current assignment
    @param ourTokenId ID of our token
    @return address address of the owner
    */
    function unassignedOwnerOf(uint256 ourTokenId) external view returns (address);

    /**
    @notice Sends events for a token when the assigned-to token has been transferred
    @param from Sender address
    @param to Recipient address
    @param tokenId ID of the token
    */
    function onAssignedTransfer(address from, address to, uint256 tokenId) external;

    /**
    @notice Updates the real underlying ownership of a token in storage (if different from current)
    @param tokenId ID of the token
    */
    function updateOwnership(uint256 tokenId) external;
}