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
    @notice Checks permissions for assignment
    @param ourTokenId the tokenID to assign
    @param target the address of the target
    @param targetTokenId the tokenID of the target
    @param targetOwner the ownerOf of the target
    @param by the account invoking the assignment to Patchwork Protocol
    @param scopeName the scope name of the contract to assign to
    */
    function allowAssignment(uint256 ourTokenId, address target, uint256 targetTokenId, address targetOwner, address by, string memory scopeName) external returns (bool);

    /**
    @notice A deliberately incompatible function to block implementing both assignable and patch
    @return bytes2 Always returns 0x0000
    */
    function patchworkCompatible_() external pure returns (bytes2);
}