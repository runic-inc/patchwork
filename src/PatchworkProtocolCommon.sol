// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**

    ____        __       __                       __  
   / __ \____ _/ /______/ /_ _      ______  _____/ /__
  / /_/ / __ `/ __/ ___/ __ \ | /| / / __ \/ ___/ //_/
 / ____/ /_/ / /_/ /__/ / / / |/ |/ / /_/ / /  / ,<   
/_/ ___\__,_/\__/\___/_/ /_/|__/|__/\____/_/  /_/|_|  
   / __ \_________  / /_____  _________  / /          
  / /_/ / ___/ __ \/ __/ __ \/ ___/ __ \/ /           
 / ____/ /  / /_/ / /_/ /_/ / /__/ /_/ / /            
/_/   /_/   \____/\__/\____/\___/\____/_/          

Storage layout and common functions

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPatchworkProtocol.sol";
import "./interfaces/IPatchworkScoped.sol";

/** 
@title Patchwork Protocol Storage layout and common functions
@author Runic Labs, Inc
*/
contract PatchworkProtocolCommon is Ownable, ReentrancyGuard{

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

    /// Proposed assigner delegate
    IPatchworkProtocol.ProposedAssignerDelegate internal _proposedAssignerDelegate;

    /// Assigner module
    address internal _assignerDelegate;

    /**
    @notice Memoizing wrapper for IPatchworkScoped.getScopeName()
    @param addr Address to check
    @return scopeName return value of IPatchworkScoped(addr).getScopeName()
    */
    function _getScopeName(address addr) internal returns (string memory scopeName) {
        scopeName = _scopeNameCache[addr];
        if (bytes(scopeName).length == 0) {
            scopeName = IPatchworkScoped(addr).getScopeName();
            _scopeNameCache[addr] = scopeName;
        }
    }

    /**
    @notice Requires that scopeName is present
    @dev will revert with ScopeDoesNotExist if not present
    @return scope the scope
    */
    function _mustHaveScope(string memory scopeName) internal view returns (IPatchworkProtocol.Scope storage scope) {
        scope = _scopes[scopeName];
        if (scope.owner == address(0)) {
            revert IPatchworkProtocol.ScopeDoesNotExist(scopeName);
        }
    }

    /**
    @notice Requires that addr is whitelisted if whitelisting is enabled
    @dev will revert with NotWhitelisted if whitelisting is enabled and address is not whitelisted
    @param scopeName the name of the scope
    @param scope the scope
    @param addr the address to check
    */
    function _mustBeWhitelisted(string memory scopeName, IPatchworkProtocol.Scope storage scope, address addr) internal view {
        if (scope.requireWhitelist && !scope.whitelist[addr]) {
            revert IPatchworkProtocol.NotWhitelisted(scopeName, addr);
        }
    }
}