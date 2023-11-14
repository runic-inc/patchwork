// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkNFT.sol";
import "./IPatchworkSingleAssignableNFT.sol";
import "./IPatchworkMultiAssignableNFT.sol";
import "./IPatchworkLiteRef.sol";
import "./IPatchworkPatch.sol";
import "./IPatchwork1155Patch.sol";
import "./IPatchworkAccountPatch.sol";
import "./IPatchworkProtocol.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/** 
@title Patchwork Protocol
@author Runic Labs, Inc
@notice Manages data integrity of relational NFTs implemented with Patchwork interfaces 
*/
contract PatchworkProtocol is IPatchworkProtocol {

    /// Scopes
    mapping(string => Scope) private _scopes;

    /**
    @notice unique references
    @dev A hash of target + targetTokenId + literef provides uniqueness
    */
    mapping(bytes32 => bool) _liteRefs;

    /**
    @dev See {IPatchworkProtocol-claimScope}
    */
    function claimScope(string calldata scopeName) public {
        Scope storage s = _scopes[scopeName];
        if (s.owner != address(0)) {
            revert ScopeExists(scopeName);
        }
        s.owner = msg.sender;
        s.requireWhitelist = true; // better security by default
        emit ScopeClaim(scopeName, msg.sender);
    }

    /**
    @dev See {IPatchworkProtocol-transferScopeOwnership}
    */
    function transferScopeOwnership(string calldata scopeName, address newOwner) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        if (newOwner == address(0)) {
            revert ScopeTransferNotAllowed(address(0));
        }
        s.ownerElect = newOwner;
        emit ScopeTransferElect(scopeName, s.owner, s.ownerElect);
    }

    /**
    @dev See {IPatchworkProtocol-cancelScopeTransfer}
    */
    function cancelScopeTransfer(string calldata scopeName) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        emit ScopeTransferCancel(scopeName, s.owner, s.ownerElect);
        s.ownerElect = address(0);
    }

    /**
    @dev See {IPatchworkProtocol-acceptScopeTransfer}
    */
    function acceptScopeTransfer(string calldata scopeName) public {
        Scope storage s = _mustHaveScope(scopeName);
        if (s.ownerElect == msg.sender) {
            address oldOwner = s.owner;
            s.owner = msg.sender;
            s.ownerElect = address(0);
            emit ScopeTransfer(scopeName, oldOwner, msg.sender);
        } else {
            revert NotAuthorized(msg.sender);
        }
    }

    /**
    @dev See {IPatchworkProtocol-getScopeOwnerElect}
    */
    function getScopeOwnerElect(string calldata scopeName) public view returns (address ownerElect) {
        return _scopes[scopeName].ownerElect;
    }

    /**
    @dev See {IPatchworkProtocol-getScopeOwner}
    */
    function getScopeOwner(string calldata scopeName) public view returns (address owner) {
        return _scopes[scopeName].owner;
    }

    /**
    @dev See {IPatchworkProtocol-addOperator}
    */
    function addOperator(string calldata scopeName, address op) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        s.operators[op] = true;
        emit ScopeAddOperator(scopeName, msg.sender, op);
    }

    /**
    @dev See {IPatchworkProtocol-removeOperator}
    */
    function removeOperator(string calldata scopeName, address op) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        s.operators[op] = false;
        emit ScopeRemoveOperator(scopeName, msg.sender, op);
    }

    /**
    @dev See {IPatchworkProtocol-setScopeRules}
    */
    function setScopeRules(string calldata scopeName, bool allowUserPatch, bool allowUserAssign, bool requireWhitelist) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        s.allowUserPatch = allowUserPatch;
        s.allowUserAssign = allowUserAssign;
        s.requireWhitelist = requireWhitelist;
        emit ScopeRuleChange(scopeName, msg.sender, allowUserPatch, allowUserAssign, requireWhitelist);
    }

    /**
    @dev See {IPatchworkProtocol-addWhitelist}
    */
    function addWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(s);
        s.whitelist[addr] = true;
        emit ScopeWhitelistAdd(scopeName, msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-removeWhitelist}
    */
    function removeWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(s);
        s.whitelist[addr] = false;
        emit ScopeWhitelistRemove(scopeName, msg.sender, addr);
    }

    /**
    @dev See {IPatchworkProtocol-createPatch}
    */
    function createPatch(address owner, address originalNFTAddress, uint originalNFTTokenId, address patchAddress) public returns (uint256 tokenId) {
        IPatchworkPatch patch = IPatchworkPatch(patchAddress);
        string memory scopeName = patch.getScopeName();
        // mint a Patch that is soulbound to the originalNFT using the contract address at patchAddress which must support Patchwork metadata
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) {
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        // limit this to one unique patch (originalNFTAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalNFTAddress, originalNFTTokenId, patchAddress));
        if (scope.uniquePatches[_hash]) {
            revert AlreadyPatched(originalNFTAddress, originalNFTTokenId, patchAddress);
        }
        scope.uniquePatches[_hash] = true;
        tokenId = patch.mintPatch(owner, originalNFTAddress, originalNFTTokenId);
        emit Patch(owner, originalNFTAddress, originalNFTTokenId, patchAddress, tokenId);
        return tokenId;
    }

   /**
    @dev See {IPatchworkProtocol-create1155Patch}
    */
    function create1155Patch(address to, address originalNFTAddress, uint originalNFTTokenId, address originalAccount, address patchAddress) public returns (uint256 tokenId) {
        IPatchwork1155Patch patch = IPatchwork1155Patch(patchAddress);
        string memory scopeName = patch.getScopeName();
        // mint a Patch that is soulbound to the originalNFT using the contract address at patchAddress which must support Patchwork metadata
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) {
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        // limit this to one unique patch (originalNFTAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalNFTAddress, originalNFTTokenId, originalAccount, patchAddress));
        if (scope.uniquePatches[_hash]) {
            revert ERC1155AlreadyPatched(originalNFTAddress, originalNFTTokenId, originalAccount, patchAddress);
        }
        scope.uniquePatches[_hash] = true;
        tokenId = patch.mintPatch(to, originalNFTAddress, originalNFTTokenId, originalAccount);
        emit ERC1155Patch(to, originalNFTAddress, originalNFTTokenId, originalAccount, patchAddress, tokenId);
        return tokenId;
    }
    /**
    @dev See {IPatchworkProtocol-createAccountPatch}
    */
    function createAccountPatch(address owner, address originalAddress, address patchAddress) public returns (uint256 tokenId) {
        IPatchworkAccountPatch patch = IPatchworkAccountPatch(patchAddress);
        string memory scopeName = patch.getScopeName();
        // mint a Patch that is soulbound to the originalNFT using the contract address at patchAddress which must support Patchwork metadata
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch) { // This allows any user to patch any address
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        // limit this to one unique patch (originalAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalAddress, patchAddress));
        if (scope.uniquePatches[_hash]) {
            revert AccountAlreadyPatched(originalAddress, patchAddress);
        }
        scope.uniquePatches[_hash] = true;
        tokenId = patch.mintPatch(owner, originalAddress);
        emit AccountPatch(owner, originalAddress, patchAddress, tokenId);
        return tokenId;
    }

    /**
    @dev See {IPatchworkProtocol-assignNFT}
    */
    function assignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        uint64 ref = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        IPatchworkLiteRef(target).addReference(targetTokenId, ref);
    }

    /**
    @dev See {IPatchworkProtocol-assignNFTDirect}
    */
    function assignNFTDirect(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        uint64 ref = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        IPatchworkLiteRef(target).addReferenceDirect(targetTokenId, ref, targetMetadataId);
    }

    /**
    @dev See {IPatchworkProtocol-batchAssignNFT}
    */
    function batchAssignNFT(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        (uint64[] memory refs, ) = _batchAssignCommon(fragments, tokenIds, target, targetTokenId);
        IPatchworkLiteRef(target).batchAddReferences(targetTokenId, refs);
    }

    /**
    @dev See {IPatchworkProtocol-batchAssignNFTDirect}
    */
    function batchAssignNFTDirect(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        (uint64[] memory refs, ) = _batchAssignCommon(fragments, tokenIds, target, targetTokenId);
        IPatchworkLiteRef(target).batchAddReferencesDirect(targetTokenId, refs, targetMetadataId);
    }

    /**
    @dev Common function to handle the batch assignment of NFTs.
    */
    function _batchAssignCommon(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) private returns (uint64[] memory refs, address targetOwner) {
        if (fragments.length != tokenIds.length) {
            revert BadInputLengths();
        }
        targetOwner = IERC721(target).ownerOf(targetTokenId);
        refs = new uint64[](fragments.length);
        for (uint i = 0; i < fragments.length; i++) {
            address fragment = fragments[i];
            uint256 fragmentTokenId = tokenIds[i];
            refs[i] = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        }
    }

    /**
    @notice Performs assignment of an IPatchworkAssignableNFT to an IPatchworkLiteRef
    @param fragment the IPatchworkAssignableNFT's address
    @param fragmentTokenId the IPatchworkAssignableNFT's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    @param targetOwner the owner address of the target
    @return uint64 literef of assignable in target
    */
    function _doAssign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, address targetOwner) private mustNotBeFrozen(fragment, fragmentTokenId) returns (uint64) {
        if (fragment == target && fragmentTokenId == targetTokenId) {
            revert SelfAssignmentNotAllowed(fragment, fragmentTokenId);
        }
        IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(fragment);
        if (_isLocked(fragment, fragmentTokenId)) {
            revert Locked(fragment, fragmentTokenId);
        }
        // Use the target's scope for general permission and check the fragment for detailed permissions
        string memory targetScopeName = IPatchworkNFT(target).getScopeName();
        Scope storage targetScope = _mustHaveScope(targetScopeName);
        _mustBeWhitelisted(targetScopeName, targetScope, target);
        {
            // Whitelist check, these variables do not need to stay in the function level stack
            string memory fragmentScopeName = assignableNFT.getScopeName();
            Scope storage fragmentScope = _mustHaveScope(fragmentScopeName);
            _mustBeWhitelisted(fragmentScopeName, fragmentScope, fragment);
        }
        if (targetScope.owner == msg.sender || targetScope.operators[msg.sender]) {
            // all good
        } else if (targetScope.allowUserAssign) {
            // msg.sender must own the target
            if (targetOwner != msg.sender) {
                revert NotAuthorized(msg.sender);
            }
        } else {
            revert NotAuthorized(msg.sender);
        }
        if (!IPatchworkAssignableNFT(fragment).allowAssignment(fragmentTokenId, target, targetTokenId, targetOwner, msg.sender, targetScopeName)) {
            revert NotAuthorized(msg.sender);
        }
        bytes32 targetRef;
        // reduce stack to stay under limit
        address _target = target;
        uint256 _targetTokenId = targetTokenId;
        address _fragment = fragment;
        uint256 _fragmentTokenId = fragmentTokenId;
        (uint64 ref, bool redacted) = IPatchworkLiteRef(_target).getLiteReference(_fragment, _fragmentTokenId);
        // targetRef is a compound key (targetAddr+targetTokenID+fragmentAddr+fragmentTokenID) - blocks duplicate assignments
        targetRef = keccak256(abi.encodePacked(_target, _targetTokenId, ref));
        if (ref == 0) {
            revert FragmentUnregistered(address(_fragment));
        }
        if (redacted) {
            revert FragmentRedacted(address(_fragment));
        }
        if (_liteRefs[targetRef]) {
            revert FragmentAlreadyAssigned(address(_fragment), _fragmentTokenId);
        }
        // call assign on the fragment
        assignableNFT.assign(_fragmentTokenId, _target, _targetTokenId);
        // add to our storage of assignments
        _liteRefs[targetRef] = true;
        emit Assign(targetOwner, _fragment, _fragmentTokenId, _target, _targetTokenId);
        return ref;
    }

    /**
    @dev See {IPatchworkProtocol-unassignNFT}
    */
    function unassignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignNFT(fragment, fragmentTokenId, target, targetTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassignNFTDirect}
    */
    function unassignNFTDirect(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignNFT(fragment, fragmentTokenId, target, targetTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle the unassignment of NFTs.
    */
    function _unassignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool isDirect, uint256 targetMetadataId) private {
        if (IERC165(fragment).supportsInterface(type(IPatchworkMultiAssignableNFT).interfaceId)) {
            if (isDirect) {
                unassignMultiNFTDirect(fragment, fragmentTokenId, target, targetTokenId, targetMetadataId);
            } else {
                unassignMultiNFT(fragment, fragmentTokenId, target, targetTokenId);
            }
        } else if (IERC165(fragment).supportsInterface(type(IPatchworkSingleAssignableNFT).interfaceId)) {
            (address _target, uint256 _targetTokenId) = IPatchworkSingleAssignableNFT(fragment).getAssignedTo(fragmentTokenId);
            if (target != _target || _targetTokenId != targetTokenId) {
                revert FragmentNotAssignedToTarget(fragment, fragmentTokenId, target, targetTokenId);
            }
            if (isDirect) {
                unassignSingleNFTDirect(fragment, fragmentTokenId, targetMetadataId);
            } else {
                unassignSingleNFT(fragment, fragmentTokenId);
            }
        } else {
            revert UnsupportedContract();
        }
    }

    /**
    @dev See {IPatchworkProtocol-unassignMultiNFT}
    */
    function unassignMultiNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignMultiCommon(fragment, fragmentTokenId, target, targetTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassignMultiNFTDirect}
    */
    function unassignMultiNFTDirect(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) public mustNotBeFrozen(target, targetTokenId) {
        _unassignMultiCommon(fragment, fragmentTokenId, target, targetTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle the unassignment of multi NFTs.
    */
    function _unassignMultiCommon(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool isDirect, uint256 targetMetadataId) private {
        IPatchworkMultiAssignableNFT assignable = IPatchworkMultiAssignableNFT(fragment);
        string memory scopeName = assignable.getScopeName();
        if (!assignable.isAssignedTo(fragmentTokenId, target, targetTokenId)) {
            revert FragmentNotAssignedToTarget(fragment, fragmentTokenId, target, targetTokenId);
        }
        _doUnassign(fragment, fragmentTokenId, target, targetTokenId, isDirect, targetMetadataId, scopeName);
        assignable.unassign(fragmentTokenId, target, targetTokenId);
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingleNFT}
    */
    function unassignSingleNFT(address fragment, uint fragmentTokenId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        _unassignSingleCommon(fragment, fragmentTokenId, false, 0);
    }

    /**
    @dev See {IPatchworkProtocol-unassignSingleNFTDirect}
    */
    function unassignSingleNFTDirect(address fragment, uint fragmentTokenId, uint256 targetMetadataId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        _unassignSingleCommon(fragment, fragmentTokenId, true, targetMetadataId);
    }

    /**
    @dev Common function to handle the unassignment of single NFTs.
    */
    function _unassignSingleCommon(address fragment, uint fragmentTokenId, bool isDirect, uint256 targetMetadataId) private {
        IPatchworkSingleAssignableNFT assignableNFT = IPatchworkSingleAssignableNFT(fragment);
        string memory scopeName = assignableNFT.getScopeName();
        (address target, uint256 targetTokenId) = assignableNFT.getAssignedTo(fragmentTokenId);
        if (target == address(0)) {
            revert FragmentNotAssigned(fragment, fragmentTokenId);
        }
        _doUnassign(fragment, fragmentTokenId, target, targetTokenId, isDirect, targetMetadataId, scopeName);
        assignableNFT.unassign(fragmentTokenId);
    }

    /**
    @notice Performs unassignment of an IPatchworkAssignableNFT to an IPatchworkLiteRef
    @param fragment the IPatchworkAssignableNFT's address
    @param fragmentTokenId the IPatchworkAssignableNFT's tokenId
    @param target the IPatchworkLiteRef target's address
    @param targetTokenId the IPatchworkLiteRef target's tokenId
    @param scopeName the name of the assignable's scope
    */
    function _doUnassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, bool direct, uint256 targetMetadataId, string memory scopeName) private {
        Scope storage scope = _mustHaveScope(scopeName);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserAssign) {
            if (IERC721(target).ownerOf(targetTokenId) != msg.sender) {
                revert NotAuthorized(msg.sender);
            }
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        (uint64 ref, ) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (ref == 0) {
            revert FragmentUnregistered(address(fragment));
        }
        bytes32 targetRef = keccak256(abi.encodePacked(target, targetTokenId, ref));
        if (!_liteRefs[targetRef]) {
            revert RefNotFound(target, fragment, fragmentTokenId);
        }
        delete _liteRefs[targetRef];
        if (direct) {
            IPatchworkLiteRef(target).removeReferenceDirect(targetTokenId, ref, targetMetadataId);
        } else {
            IPatchworkLiteRef(target).removeReference(targetTokenId, ref);
        }

        emit Unassign(IERC721(target).ownerOf(targetTokenId), fragment, fragmentTokenId, target, targetTokenId);
    }

    /**
    @dev See {IPatchworkProtocol-applyTransfer}
    */
    function applyTransfer(address from, address to, uint256 tokenId) public {
        address nft = msg.sender;
        if (IERC165(nft).supportsInterface(type(IPatchworkSingleAssignableNFT).interfaceId)) {
            IPatchworkSingleAssignableNFT assignableNFT = IPatchworkSingleAssignableNFT(nft);
            (address addr,) = assignableNFT.getAssignedTo(tokenId);
            if (addr != address(0)) {
                revert TransferBlockedByAssignment(nft, tokenId);
            }
        }
        if (IERC165(nft).supportsInterface(type(IPatchworkPatch).interfaceId)) {
            revert TransferNotAllowed(nft, tokenId);
        }
        if (IERC165(nft).supportsInterface(type(IPatchworkNFT).interfaceId)) {
            if (IPatchworkNFT(nft).locked(tokenId)) {
                revert Locked(nft, tokenId);
            }
        }
        if (IERC165(nft).supportsInterface(type(IPatchworkLiteRef).interfaceId)) {
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i], nft, tokenId);
                }
            }
        }
    }

    function _applyAssignedTransfer(address nft, address from, address to, uint256 tokenId, address assignedToNFT_, uint256 assignedToTokenId_) private {
        if (!IERC165(nft).supportsInterface(type(IPatchworkSingleAssignableNFT).interfaceId)) {
            revert NotPatchworkAssignable(nft);
        }
        (address assignedToNFT, uint256 assignedToTokenId) = IPatchworkSingleAssignableNFT(nft).getAssignedTo(tokenId);
        // 2-way Check the assignment to prevent spoofing
        if (assignedToNFT_ != assignedToNFT || assignedToTokenId_ != assignedToTokenId) {
            revert DataIntegrityError(assignedToNFT_, assignedToTokenId_, assignedToNFT, assignedToTokenId);
        }
        IPatchworkSingleAssignableNFT(nft).onAssignedTransfer(from, to, tokenId);
        if (IERC165(nft).supportsInterface(type(IPatchworkLiteRef).interfaceId)) {
            address nft_ = nft; // local variable prevents optimizer stack issue in v0.8.18
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i], nft_, tokenId);
                }
            }
        }
    }

    /**
    @dev See {IPatchworkProtocol-updateOwnershipTree}
    */ 
    function updateOwnershipTree(address nft, uint256 tokenId) public {
        if (IERC165(nft).supportsInterface(type(IPatchworkLiteRef).interfaceId)) {
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllStaticReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    updateOwnershipTree(addresses[i], tokenIds[i]);
                }
            }
        }
        if (IERC165(nft).supportsInterface(type(IPatchworkSingleAssignableNFT).interfaceId)) {
            IPatchworkSingleAssignableNFT(nft).updateOwnership(tokenId);
        } else if (IERC165(nft).supportsInterface(type(IPatchworkPatch).interfaceId)) {
            IPatchworkPatch(nft).updateOwnership(tokenId);
        }
    }

    /**
    @notice Requires that scopeName is present
    @dev will revert with ScopeDoesNotExist if not present
    @return scope the scope
    */
    function _mustHaveScope(string memory scopeName) private view returns (Scope storage scope) {
        scope = _scopes[scopeName];
        if (scope.owner == address(0)) {
            revert ScopeDoesNotExist(scopeName);
        }
    }

    /**
    @notice Requires that addr is whitelisted if whitelisting is enabled
    @dev will revert with NotWhitelisted if whitelisting is enabled and address is not whitelisted
    @param scopeName the name of the scope
    @param scope the scope
    @param addr the address to check
    */
    function _mustBeWhitelisted(string memory scopeName, Scope storage scope, address addr) private view {
        if (scope.requireWhitelist && !scope.whitelist[addr]) {
            revert NotWhitelisted(scopeName, addr);
        }
    }

    /**
    @notice Requires that msg.sender is owner of scope
    @dev will revert with NotAuthorized if msg.sender is not owner
    @param scope the scope
    */
    function _mustBeOwner(Scope storage scope) private view {
        if (msg.sender != scope.owner) {
            revert NotAuthorized(msg.sender);
        }
    }

    /**
    @notice Requires that msg.sender is owner or operator of scope
    @dev will revert with NotAuthorized if msg.sender is not owner or operator
    @param scope the scope
    */
    function _mustBeOwnerOrOperator(Scope storage scope) private view {
        if (msg.sender != scope.owner && !scope.operators[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }
    }

    /**
    @notice Requires that nft is not frozen
    @dev will revert with Frozen if nft is frozen
    @param nft the address of nft
    @param tokenId the tokenId of nft
    */
    modifier mustNotBeFrozen(address nft, uint256 tokenId) {
        if (_isFrozen(nft, tokenId)) {
            revert Frozen(nft, tokenId);
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
        if (IERC165(nft).supportsInterface(type(IPatchworkNFT).interfaceId)) {
            if (IPatchworkNFT(nft).frozen(tokenId)) {
                return true;
            }
            if (IERC165(nft).supportsInterface(type(IPatchworkSingleAssignableNFT).interfaceId)) {
                (address assignedAddr, uint256 assignedTokenId) = IPatchworkSingleAssignableNFT(nft).getAssignedTo(tokenId);
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
        if (IERC165(nft).supportsInterface(type(IPatchworkNFT).interfaceId)) {
            if (IPatchworkNFT(nft).locked(tokenId)) {
                return true;
            }
        }
        return false;
    }
}