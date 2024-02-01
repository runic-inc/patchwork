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

Assigner Module

*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./PatchworkProtocolCommon.sol";
import "./interfaces/IPatchwork721.sol";
import "./interfaces/IPatchworkSingleAssignable.sol";
import "./interfaces/IPatchworkMultiAssignable.sol";
import "./interfaces/IPatchworkLiteRef.sol";

/** 
@title Patchwork Protocol Assigner Module
@author Runic Labs, Inc
*/
contract PatchworkProtocolAssigner is PatchworkProtocolCommon {

    /// The denominator for fee basis points
    uint256 private constant _FEE_BASIS_DENOM = 10000;

    constructor(address owner_) PatchworkProtocolCommon(owner_) {}
    
    /**
    @dev common to assigns
    @dev fees are processed per-assignment
    */
    function _handleAssignFee(uint256 value, string memory scopeName, IPatchworkProtocol.Scope storage scope, address fragmentAddress) private returns (uint256 scopeFee, uint256 protocolFee, uint256 valueRemaining) {
        uint256 assignFee = scope.assignFees[fragmentAddress];
        if (value < assignFee) {
            revert IPatchworkProtocol.IncorrectFeeAmount();
        }
        if (value > 0) {
            uint256 assignBp;
            IPatchworkProtocol.FeeConfigOverride storage feeOverride = _scopeFeeOverrides[scopeName];
            if (feeOverride.active) {
                assignBp = feeOverride.assignBp;
            } else {
                assignBp = _protocolFeeConfig.assignBp;
            }
            protocolFee = assignFee * assignBp / _FEE_BASIS_DENOM;
            scopeFee = assignFee - protocolFee;
            _protocolBalance += protocolFee;
            scope.balance += scopeFee;
            valueRemaining = value - assignFee;
        }
    }

    /**
    @dev See {IPatchworkProtocol-assign}
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public payable mustNotBeFrozen(target, targetTokenId) {
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        (uint64 ref, uint256 valueRemaining) = _doAssign(msg.value, fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        if (valueRemaining > 0) {
            revert IPatchworkProtocol.IncorrectFeeAmount();
        }
        IPatchworkLiteRef(target).addReference(targetTokenId, ref);
    }

    /**
    @dev See {IPatchworkProtocol-assign}
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public payable mustNotBeFrozen(target, targetTokenId) {
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        (uint64 ref, uint256 valueRemaining) = _doAssign(msg.value, fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        if (valueRemaining > 0) {
            revert IPatchworkProtocol.IncorrectFeeAmount();
        }
        IPatchworkLiteRef(target).addReference(targetTokenId, ref, targetMetadataId);
    }

    /**
    @dev See {IPatchworkProtocol-assignBatch}
    */
    function assignBatch(address[] calldata fragments, uint256[] calldata tokenIds, address target, uint256 targetTokenId) public payable mustNotBeFrozen(target, targetTokenId) {
        (uint64[] memory refs, ) = _batchAssignCommon(fragments, tokenIds, target, targetTokenId);
        IPatchworkLiteRef(target).addReferenceBatch(targetTokenId, refs);
    }

    /**
    @dev See {IPatchworkProtocol-assignBatch}
    */
    function assignBatch(address[] calldata fragments, uint256[] calldata tokenIds, address target, uint256 targetTokenId, uint256 targetMetadataId) public payable mustNotBeFrozen(target, targetTokenId) {
        (uint64[] memory refs, ) = _batchAssignCommon(fragments, tokenIds, target, targetTokenId);
        IPatchworkLiteRef(target).addReferenceBatch(targetTokenId, refs, targetMetadataId);
    }

    /**
    @dev Common function to handle the batch assignments.
    */
    function _batchAssignCommon(address[] calldata fragments, uint256[] calldata tokenIds, address target, uint256 targetTokenId) private returns (uint64[] memory refs, address targetOwner) {
        if (fragments.length != tokenIds.length) {
            revert IPatchworkProtocol.BadInputLengths();
        }
        targetOwner = IERC721(target).ownerOf(targetTokenId);
        refs = new uint64[](fragments.length);
        uint256 value = msg.value;
        for (uint i = 0; i < fragments.length; i++) {
            address fragment = fragments[i];
            uint256 fragmentTokenId = tokenIds[i];
            (refs[i], value) = _doAssign(value, fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        }
        // If the correct fee amount is provided there should be no remainder after all assignments are processed
        if (value > 0) {
            revert IPatchworkProtocol.IncorrectFeeAmount();
        }
    }

    /**
    @notice Performs assignment of an IPatchworkAssignable to an IPatchworkLiteRef
    @param value the remaining message value after any previous assignments in this tx
    @param fragment the IPatchworkAssignable's address
    @param fragmentTokenId the IPatchworkAssignable's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    @param targetOwner the owner address of the target
    @return ref literef of assignable in target
    @return valueRemaining message value remaining after fee
    */
    function _doAssign(uint256 value, address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, address targetOwner) private mustNotBeFrozen(fragment, fragmentTokenId) returns (uint64 ref, uint256 valueRemaining) {
        if (fragment == target && fragmentTokenId == targetTokenId) {
            revert IPatchworkProtocol.SelfAssignmentNotAllowed(fragment, fragmentTokenId);
        }
        uint256 scopeFee;
        uint256 protocolFee;
        // Use the target's scope for general permission and check the fragment for detailed permissions
        (scopeFee, protocolFee, valueRemaining) = _doAssignPermissionsAndFees(value, fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        // Handle storage and duplicate checks
        ref = _doAssignStorageAndDupes(fragment, fragmentTokenId, target, targetTokenId);
        // these two end up beyond stack depth on some compiler settings.
        emit IPatchworkProtocol.Assign(targetOwner, fragment, fragmentTokenId, target, targetTokenId, scopeFee, protocolFee);
        return (ref, valueRemaining);
    }

    /**
    @notice Handles assignment permissions and fees
    @param value the remaining message value after any previous assignments in this tx
    @param fragment the IPatchworkAssignable's address
    @param fragmentTokenId the IPatchworkAssignable's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    @param targetOwner the owner address of the target
    @return scopeFee the scope fee taken
    @return protocolFee the protocol fee taken
    @return valueRemaining the remaining message value after fees taken
    */
    function _doAssignPermissionsAndFees(uint256 value, address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, address targetOwner) private returns (uint256 scopeFee, uint256 protocolFee, uint256 valueRemaining) {
        string memory targetScopeName = _getScopeName(target);
        if (!IPatchworkAssignable(fragment).allowAssignment(fragmentTokenId, target, targetTokenId, targetOwner, msg.sender, targetScopeName)) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        IPatchworkProtocol.Scope storage targetScope = _mustHaveScope(targetScopeName);
        _mustBeWhitelisted(targetScopeName, targetScope, target);
        if (targetScope.owner == msg.sender || targetScope.operators[msg.sender]) {
            // all good
        } else if (targetScope.allowUserAssign) {
            // msg.sender must own the target
            if (targetOwner != msg.sender) {
                revert IPatchworkProtocol.NotAuthorized(msg.sender);
            }
        } else {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        if (_isLocked(fragment, fragmentTokenId)) {
            revert IPatchworkProtocol.Locked(fragment, fragmentTokenId);
        }
        // Whitelist check, these variables do not need to stay in the function level stack
        string memory fragmentScopeName = _getScopeName(fragment);
        IPatchworkProtocol.Scope storage fragmentScope = _mustHaveScope(fragmentScopeName);
        _mustBeWhitelisted(fragmentScopeName, fragmentScope, fragment);
        (scopeFee, protocolFee, valueRemaining) = _handleAssignFee(value, fragmentScopeName, fragmentScope, fragment);
    }

    /**
    @notice Handles assignment storage and duplicate checks
    @param fragment the IPatchworkAssignable's address
    @param fragmentTokenId the IPatchworkAssignable's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    */
    function _doAssignStorageAndDupes(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) private returns (uint64 ref) {
        bool redacted;
        (ref, redacted) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (redacted) {
            revert IPatchworkProtocol.FragmentRedacted(address(fragment));
        }
        if (ref == 0) {
            revert IPatchworkProtocol.FragmentUnregistered(address(fragment));
        }
        // targetRef is a compound key (targetAddr+targetTokenID+ref) - blocks duplicate assignments
        bytes32 targetRef = keccak256(abi.encodePacked(target, targetTokenId, ref));
        if (_liteRefs[targetRef]) {
            revert IPatchworkProtocol.FragmentAlreadyAssigned(address(fragment), fragmentTokenId);
        }
        // add to our storage of assignments
        _liteRefs[targetRef] = true;
        // call assign on the fragment
        IPatchworkAssignable(fragment).assign(fragmentTokenId, target, targetTokenId);
    }
    
    /**
    @dev See {IPatchworkProtocol-unassign}
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        _unassign(fragment, fragmentTokenId, target, targetTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassign}
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        _unassign(fragment, fragmentTokenId, target, targetTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle unassignments.
    */
    function _unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool isDirect, uint256 targetMetadataId) private {
        if (IERC165(fragment).supportsInterface(type(IPatchworkMultiAssignable).interfaceId)) {
            if (isDirect) {
                unassignMulti(fragment, fragmentTokenId, target, targetTokenId, targetMetadataId);
            } else {
                unassignMulti(fragment, fragmentTokenId, target, targetTokenId);
            }
        } else if (IERC165(fragment).supportsInterface(type(IPatchworkSingleAssignable).interfaceId)) {
            (address _target, uint256 _targetTokenId) = IPatchworkSingleAssignable(fragment).getAssignedTo(fragmentTokenId);
            if (target != _target || _targetTokenId != targetTokenId) {
                revert IPatchworkProtocol.FragmentNotAssignedToTarget(fragment, fragmentTokenId, target, targetTokenId);
            }
            if (isDirect) {
                unassignSingle(fragment, fragmentTokenId, targetMetadataId);
            } else {
                unassignSingle(fragment, fragmentTokenId);
            }
        } else {
            revert IPatchworkProtocol.UnsupportedContract();
        }
    }

    /**
    @dev See {IPatchworkProtocol-unassignMulti}
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignMultiCommon(fragment, fragmentTokenId, target, targetTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassignMulti}
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignMultiCommon(fragment, fragmentTokenId, target, targetTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle the unassignment of multi assignables.
    */
    function _unassignMultiCommon(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool isDirect, uint256 targetMetadataId) private {
        IPatchworkMultiAssignable assignable = IPatchworkMultiAssignable(fragment);
        if (!assignable.isAssignedTo(fragmentTokenId, target, targetTokenId)) {
            revert IPatchworkProtocol.FragmentNotAssignedToTarget(fragment, fragmentTokenId, target, targetTokenId);
        }
        string memory scopeName = _getScopeName(target);
        _doUnassign(fragment, fragmentTokenId, target, targetTokenId, isDirect, targetMetadataId, scopeName);
        assignable.unassign(fragmentTokenId, target, targetTokenId);
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingle}
    */
    function unassignSingle(address fragment, uint256 fragmentTokenId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        _unassignSingleCommon(fragment, fragmentTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingle}
    */
    function unassignSingle(address fragment, uint256 fragmentTokenId, uint256 targetMetadataId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        _unassignSingleCommon(fragment, fragmentTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle the unassignment of single assignables.
    */
    function _unassignSingleCommon(address fragment, uint256 fragmentTokenId, bool isDirect, uint256 targetMetadataId) private {
        IPatchworkSingleAssignable assignable = IPatchworkSingleAssignable(fragment);
        (address target, uint256 targetTokenId) = assignable.getAssignedTo(fragmentTokenId);
        if (target == address(0)) {
            revert IPatchworkProtocol.FragmentNotAssigned(fragment, fragmentTokenId);
        }
        string memory scopeName = _getScopeName(target);
        _doUnassign(fragment, fragmentTokenId, target, targetTokenId, isDirect, targetMetadataId, scopeName);
        assignable.unassign(fragmentTokenId);
    }

    /**
    @notice Performs unassignment of an IPatchworkAssignable to an IPatchworkLiteRef
    @param fragment the IPatchworkAssignable's address
    @param fragmentTokenId the IPatchworkAssignable's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    @param direct If this is calling the direct function
    @param targetMetadataId the metadataId to use on the target
    @param scopeName the name of the target's scope
    */
    function _doUnassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool direct, uint256 targetMetadataId, string memory scopeName) private {
        IPatchworkProtocol.Scope storage scope = _mustHaveScope(scopeName);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserAssign) {
            if (IERC721(target).ownerOf(targetTokenId) != msg.sender) {
                revert IPatchworkProtocol.NotAuthorized(msg.sender);
            }
            // continue
        } else {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        (uint64 ref, ) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (ref == 0) {
            revert IPatchworkProtocol.FragmentUnregistered(address(fragment));
        }
        bytes32 targetRef = keccak256(abi.encodePacked(target, targetTokenId, ref));
        if (!_liteRefs[targetRef]) {
            revert IPatchworkProtocol.RefNotFound(target, fragment, fragmentTokenId);
        }
        delete _liteRefs[targetRef];
        if (direct) {
            IPatchworkLiteRef(target).removeReference(targetTokenId, ref, targetMetadataId);
        } else {
            IPatchworkLiteRef(target).removeReference(targetTokenId, ref);
        }
        emit IPatchworkProtocol.Unassign(IERC721(fragment).ownerOf(fragmentTokenId), fragment, fragmentTokenId, target, targetTokenId);
    }

    /**
    @notice Requires that nft is not frozen
    @dev will revert with Frozen if nft is frozen
    @param nft the address of nft
    @param tokenId the tokenId of nft
    */
    modifier mustNotBeFrozen(address nft, uint256 tokenId) {
        if (_isFrozen(nft, tokenId)) {
            revert IPatchworkProtocol.Frozen(nft, tokenId);
        }
        _;
    }

    /**
    @notice Determines if nft is frozen using ownership hierarchy
    @param nft the address of nft
    @param tokenId the tokenId of nft
    @return frozen if the nft or an owner up the tree is frozen
    */
    function _isFrozen(address nft, uint256 tokenId) private view returns (bool frozen) {
        if (IERC165(nft).supportsInterface(type(IPatchwork721).interfaceId)) {
            if (IPatchwork721(nft).frozen(tokenId)) {
                return true;
            }
            if (IERC165(nft).supportsInterface(type(IPatchworkSingleAssignable).interfaceId)) {
                (address assignedAddr, uint256 assignedTokenId) = IPatchworkSingleAssignable(nft).getAssignedTo(tokenId);
                if (assignedAddr != address(0)) {
                    return _isFrozen(assignedAddr, assignedTokenId);
                }
            }
        }
        return false;
    }

    /**
    @notice Determines if nft is locked
    @param nft the address of nft
    @param tokenId the tokenId of nft
    @return locked if the nft is locked
    */
    function _isLocked(address nft, uint256 tokenId) private view returns (bool locked) {
        if (IERC165(nft).supportsInterface(type(IPatchwork721).interfaceId)) {
            if (IPatchwork721(nft).locked(tokenId)) {
                return true;
            }
        }
        return false;
    }
}