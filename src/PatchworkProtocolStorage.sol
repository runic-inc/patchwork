// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPatchworkProtocol.sol";

contract PatchworkProtocolStorage is Ownable, ReentrancyGuard{

    constructor(address owner_) Ownable(owner_) {}

    /// Scopes
    mapping(string => IPatchworkProtocol.Scope) internal _scopes;

    /**
    @notice unique references
    @dev A hash of target + targetTokenId + literef provides uniqueness
    */
    mapping(bytes32 => bool) internal _liteRefs;

    /**
    @notice unique patches
    @dev Hash of the patch mapped to a boolean indicating its uniqueness
    */
    mapping(bytes32 => bool) internal _uniquePatches;

    /// Balance of the protocol
    uint256 internal _protocolBalance;

    /**
    @notice protocol bankers
    @dev Map of addresses authorized to set fees and withdraw funds for the protocol
    @dev Does not allow for scope balance withdrawl
    */
    mapping(address => bool) internal _protocolBankers;

    /// Current protocol fee configuration
    IPatchworkProtocol.FeeConfig internal _protocolFeeConfig;

    /// Proposed protocol fee configuration
    mapping(string => IPatchworkProtocol.ProposedFeeConfig) internal _proposedFeeConfigs;

    /// scope-based fee overrides
    mapping(string => IPatchworkProtocol.FeeConfigOverride) internal _scopeFeeOverrides; 

    /// Scope name cache
    mapping(address => string) internal _scopeNameCache;

    address internal _assignerDelegate;
}