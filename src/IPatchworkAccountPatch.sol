// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
@title Patchwork Protocol Account Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchworkAccountPatch {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Creates a new token for the owner, representing a patch
    @param owner Address of the owner of the token
    @param originalNFTAddress Address of the original account
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address owner, address originalNFTAddress) external returns (uint256 tokenId);

    /**
    @notice A deliberately incompatible function to block implementing both assignable and patch
    @return bytes3 Always returns 0x00
    */
    function patchworkCompatible_() external pure returns (bytes3);
}