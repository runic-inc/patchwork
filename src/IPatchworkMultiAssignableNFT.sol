// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkAssignableNFT.sol";

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkMultiAssignableNFT is IPatchworkAssignableNFT {
    // TODO isAssignedTo
    // TODO getAssignmentCount? getAssignments paginated?
}