// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkAssignableNFT {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Assigns a token to another
    @param ourTokenId ID of our token
    @param to Address to assign to
    @param tokenId ID of the token to assign
    */
    function assign(uint256 ourTokenId, address to, uint256 tokenId) external;

    /**
    @notice Unassigns a token
    @param ourTokenId ID of our token
    */
    function unassign(uint256 ourTokenId) external;

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

    /**
    @notice A deliberately incompatible function to block implementing both assignable and patch
    @return bytes2 Always returns 0x0000
    */
    function patchworkCompatible_() external pure returns (bytes2);
}