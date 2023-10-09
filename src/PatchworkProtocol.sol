// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkNFT.sol";
import "./IPatchworkSingleAssignableNFT.sol";
import "./IPatchworkMultiAssignableNFT.sol";
import "./IPatchworkLiteRef.sol";
import "./IPatchworkPatch.sol";
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
    @dev See {IPatchworkProtocol-createAccountPatch}
    */
    function createPatch(address originalNFTAddress, uint originalNFTTokenId, address patchAddress) public returns (uint256 tokenId) {
        IPatchworkPatch patch = IPatchworkPatch(patchAddress);
        string memory scopeName = patch.getScopeName();
        // mint a Patch that is soulbound to the originalNFT using the contract address at patchAddress which must support Patchwork metadata
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, patchAddress);
        address tokenOwner = IERC721(originalNFTAddress).ownerOf(originalNFTTokenId);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch && msg.sender == tokenOwner) {
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
        tokenId = patch.mintPatch(tokenOwner, originalNFTAddress, originalNFTTokenId);
        emit Patch(tokenOwner, originalNFTAddress, originalNFTTokenId, patchAddress, tokenId);
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
        // call addReference on the target
        IPatchworkLiteRef(target).addReference(targetTokenId, ref);
    }

    /**
    @dev See {IPatchworkProtocol-batchAssignNFT}
    */
    function batchAssignNFT(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
        if (fragments.length != tokenIds.length) {
            revert BadInputLengths();
        }
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        uint64[] memory refs = new uint64[](fragments.length);
        for (uint i = 0; i < fragments.length; i++) {
            address fragment = fragments[i];
            uint256 fragmentTokenId = tokenIds[i];
            refs[i] = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        }
        IPatchworkLiteRef(target).batchAddReferences(targetTokenId, refs);
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
        // Use the fragment's scope for permissions, target already has to have fragment registered to be assignable
        string memory scopeName = assignableNFT.getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        _mustBeWhitelisted(scopeName, scope, fragment);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // Fragment and target must be same owner
            if (IERC721(fragment).ownerOf(fragmentTokenId) != targetOwner) {
                revert NotAuthorized(msg.sender);
            }
        } else if (scope.allowUserAssign) {
            // If allowUserAssign is set for this scope, the sender must own both fragment and target
            if (IERC721(fragment).ownerOf(fragmentTokenId) != msg.sender) {
                revert NotAuthorized(msg.sender);
            }
            if (targetOwner != msg.sender) {
                revert NotAuthorized(msg.sender);
            }
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        bytes32 targetRef;
        // reduce stack to stay under limit
        address _target = target;
        uint256 _targetTokenId = targetTokenId;
        address _fragment = fragment;
        uint256 _fragmentTokenId = fragmentTokenId;
        (uint64 ref, bool redacted) = IPatchworkLiteRef(_target).getLiteReference(_fragment, _fragmentTokenId);
        targetRef = keccak256(abi.encodePacked(_target, ref));
        if (ref == 0) {
            revert FragmentUnregistered(address(_fragment));
        }
        if (redacted) {
            revert FragmentRedacted(address(_fragment));
        }
        if (scope.liteRefs[targetRef]) {
            revert FragmentAlreadyAssignedInScope(scopeName, address(_fragment), _fragmentTokenId);
        }
        // call assign on the fragment
        assignableNFT.assign(_fragmentTokenId, _target, _targetTokenId);
        // add to our storage of scope->target assignments
        scope.liteRefs[targetRef] = true;
        emit Assign(targetOwner, _fragment, _fragmentTokenId, _target, _targetTokenId);
        return ref;
    }

    function unassignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public {
        if (IERC165(fragment).supportsInterface(type(IPatchworkMultiAssignableNFT).interfaceId)) {
            unassignMultiNFT(fragment, fragmentTokenId, target, targetTokenId);
        } else if (IERC165(fragment).supportsInterface(type(IPatchworkSingleAssignableNFT).interfaceId)) {
            // TODO check the target and use common logic with unassignSingleNFT - we want to revert if target doesn't match
            unassignSingleNFT(fragment, fragmentTokenId);
        } else {
            // TODO revert
        }
    }

    function unassignMultiNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public {
        // TODO refactor all of this into an internal function unassignMultiNFT to keep it clean
        // TODO what do we care about being locked, frozen, etc?
        IPatchworkMultiAssignableNFT assignable = IPatchworkMultiAssignableNFT(fragment);
        string memory scopeName = assignable.getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        // TODO permissions
        assignable.unassign(fragmentTokenId, target, targetTokenId);
        // TODO refactor to make common
        (uint64 ref, ) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (ref == 0) {
            revert FragmentUnregistered(address(fragment));
        }
        bytes32 targetRef = keccak256(abi.encodePacked(target, ref));
        if (!scope.liteRefs[targetRef]) {
            revert RefNotFoundInScope(scopeName, target, fragment, fragmentTokenId);
        }
        scope.liteRefs[targetRef] = false;
        IPatchworkLiteRef(target).removeReference(targetTokenId, ref);
        // TODO emit an event
    }

    /**
    @dev See {IPatchworkProtocol-unassignNFT}
    */
    function unassignSingleNFT(address fragment, uint fragmentTokenId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        IPatchworkSingleAssignableNFT assignableNFT = IPatchworkSingleAssignableNFT(fragment);
        string memory scopeName = assignableNFT.getScopeName();
        Scope storage scope = _mustHaveScope(scopeName);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserAssign) {
            // If allowUserAssign is set for this scope, the sender must own both fragment
            if (IERC721(fragment).ownerOf(fragmentTokenId) != msg.sender) {
                revert NotAuthorized(msg.sender);
            }
            // continue
        } else {
            revert NotAuthorized(msg.sender);
        }
        (address target, uint256 targetTokenId) = assignableNFT.getAssignedTo(fragmentTokenId);
        if (target == address(0)) {
            revert FragmentNotAssigned(fragment, fragmentTokenId);
        }
        assignableNFT.unassign(fragmentTokenId);
        (uint64 ref, ) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (ref == 0) {
            revert FragmentUnregistered(address(fragment));
        }
        bytes32 targetRef = keccak256(abi.encodePacked(target, ref));
        if (!scope.liteRefs[targetRef]) {
            revert RefNotFoundInScope(scopeName, target, fragment, fragmentTokenId);
        }
        scope.liteRefs[targetRef] = false;
        IPatchworkLiteRef(target).removeReference(targetTokenId, ref);
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
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
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
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
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
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
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