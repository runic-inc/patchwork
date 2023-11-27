// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkScoped.sol";

/**
@title Patchwork Mintable Interface
@author Runic Labs, Inc
*/
interface IPatchworkMintable is IPatchworkScoped {
    // TODO docs
    function mint(address to, bytes calldata data) external returns (uint256 tokenId);
    
    function mintBatch(address to, bytes calldata data, uint256 quantity) external returns (uint256[] memory tokenIds);
}