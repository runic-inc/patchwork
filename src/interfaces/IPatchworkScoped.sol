// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
@title Patchwork Protocol Scoped Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting scopes
*/
interface IPatchworkScoped {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external view returns (string memory);
}