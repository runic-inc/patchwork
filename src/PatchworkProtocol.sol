// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./PatchworkNFTInterface.sol";

/** 
@title Patchwork Protocol
@author Runic Labs, Inc
@notice Manages data integrity of relational NFTs implemented with Patchwork interfaces 
*/
contract PatchworkProtocol {

    error NotAuthorized(address addr);
    error ScopeExists(string scopeName);
    error ScopeDoesNotExist(string scopeName);
    error ScopeTransferNotAllowed(address to);
    error Frozen(address addr, uint256 tokenId);
    error Locked(address addr, uint256 tokenId);
    error NotWhitelisted(string scopeName, address addr);
    error AlreadyPatched(address addr, uint256 tokenId, address patchAddress);
    error BadInputLengths();
    error FragmentUnregistered(address addr);
    error FragmentRedacted(address addr);
    error FragmentAlreadyAssigned(address addr, uint256 tokenId);
    // TODO this could be an issue as we settled on single assignment b/c of ownership hierarchy
    error FragmentAlreadyAssignedInScope(string scopeName, address addr, uint256 tokenId);
    error RefNotFoundInScope(string scopeName, address target, address fragment, uint256 tokenId);
    error FragmentNotAssigned(address addr, uint256 tokenId);
    error FragmentAlreadyRegistered(address addr);
    error OutOfIDs();
    error UnsupportedTokenId(uint256 tokenId);
    error CannotLockSoulboundPatch(address addr);
    error NotFrozen(address addr, uint256 tokenId);
    error IncorrectNonce(address addr, uint256 tokenId, uint256 nonce);
    error SelfAssignmentNotAllowed(address addr, uint256 tokenId);
    error SoulboundTransferNotAllowed(address addr, uint256 tokenId);
    error TransferBlockedByAssignment(address addr, uint256 tokenId);
    error NotPatchworkAssignable(address addr);
    error DataIntegrityError(address addr, uint256 tokenId, address addr2, uint256 tokenId2);

    struct Scope {
        address owner;
        bool allowUserPatch;
        bool allowUserAssign;
        bool requireWhitelist;
        mapping(address => bool) operators;
        mapping(uint64 => bool) liteRefs; // TODO needs hash of literefaddr+ref to be unique
        mapping(address => bool) whitelist;
        mapping(bytes32 => bool) uniquePatches;
    }

    mapping(string => Scope) private _scopes;

    /**
    @notice Emitted when a fragment is assigned
    @param owner The owner of the target and fragment
    @param fragmentAddress The address of the fragment's contract
    @param fragmentTokenId The tokenId of the fragment
    @param targetAddress The address of the target's contract
    @param targetTokenId The tokenId of the target
    */
    event Assign(address indexed owner, address fragmentAddress, uint256 fragmentTokenId, address indexed targetAddress, uint256 indexed targetTokenId);

    /**
    @notice Emitted when a fragment is unassigned
    @param owner The owner of the fragment
    @param fragmentAddress The address of the fragment's contract
    @param fragmentTokenId The tokenId of the fragment
    @param targetAddress The address of the target's contract
    @param targetTokenId The tokenId of the target
    */
    event Unassign(address indexed owner, address fragmentAddress, uint256 fragmentTokenId, address indexed targetAddress, uint256 indexed targetTokenId);

    /**
    @notice Emitted when a patch is minted
    @param owner The owner of the patch
    @param originalAddress The address of the original NFT's contract
    @param originalTokenId The tokenId of the original NFT
    @param patchAddress The address of the patch's contract
    @param patchTokenId The tokenId of the patch
    */
    event Patch(address indexed owner, address originalAddress, uint256 originalTokenId, address indexed patchAddress, uint256 indexed patchTokenId);

    /**
    @notice Emitted when a new scope is claimed
    @param scopeName The name of the claimed scope
    @param owner The owner of the scope
    */
    event ScopeClaim(string indexed scopeName, address indexed owner);

    /**
    @notice Emitted when a scope is transferred
    @param scopeName The name of the transferred scope
    @param from The address transferring the scope
    @param to The recipient of the scope
    */
    event ScopeTransfer(string indexed scopeName, address indexed from, address indexed to);

    /**
    @notice Emitted when a scope has an operator added
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param operator The new operator's address
    */
    event ScopeAddOperator(string indexed scopeName, address indexed actor, address indexed operator);

    /**
    @notice Emitted when a scope has an operator removed
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param operator The operator's address being removed
    */
    event ScopeRemoveOperator(string indexed scopeName, address indexed actor, address indexed operator);

    /**
    @notice Emitted when a scope's rules are changed
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param allowUserPatch Indicates whether user patches are allowed
    @param allowUserAssign Indicates whether user assignments are allowed
    @param requireWhitelist Indicates whether a whitelist is required
    */
    event ScopeRuleChange(string indexed scopeName, address indexed actor, bool allowUserPatch, bool allowUserAssign, bool requireWhitelist);

    /**
    @notice Emitted when a scope has an address added to the whitelist
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param addr The address being added to the whitelist
    */
    event ScopeWhitelistAdd(string indexed scopeName, address indexed actor, address indexed addr);

    /**
    @notice Emitted when a scope has an address removed from the whitelist
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param addr The address being removed from the whitelist
    */
    event ScopeWhitelistRemove(string indexed scopeName, address indexed actor, address indexed addr);

    /**
    @notice Claim a scope
    @param scopeName the name of the scope
    */
    function claimScope(string calldata scopeName) public {
        Scope storage s = _scopes[scopeName];
        if (s.owner != address(0)) {
            revert ScopeExists(scopeName);
        }
        s.owner = msg.sender;
        // s.requireWhitelist = true; // better security by default - enable in future PR
        emit ScopeClaim(scopeName, msg.sender);
    }

    /**
    @notice Transfer ownership of a scope
    @param scopeName Name of the scope
    @param newOwner Address of the new owner
    */
    function transferScopeOwnership(string calldata scopeName, address newOwner) public {
        Scope storage s = _scopes[scopeName];
        if (msg.sender != s.owner) {
            revert NotAuthorized(msg.sender);
        }
        if (newOwner == address(0)) {
            revert ScopeTransferNotAllowed(address(0));
        }
        s.owner = newOwner;
        emit ScopeTransfer(scopeName, msg.sender, newOwner);
    }

    /**
    @notice Get owner of a scope
    @param scopeName Name of the scope
    @return owner Address of the scope owner
    */
    function getScopeOwner(string calldata scopeName) public view returns (address owner) {
        return _scopes[scopeName].owner;
    }

    /**
    @notice Add an operator to a scope
    @param scopeName Name of the scope
    @param op Address of the operator
    */
    function addOperator(string calldata scopeName, address op) public {
        Scope storage s = _scopes[scopeName];
        if (msg.sender != s.owner) {
            revert NotAuthorized(msg.sender);
        }
        s.operators[op] = true;
        emit ScopeAddOperator(scopeName, msg.sender, op);
    }

    /**
    @notice Remove an operator from a scope
    @param scopeName Name of the scope
    @param op Address of the operator
    */
    function removeOperator(string calldata scopeName, address op) public {
        Scope storage s = _scopes[scopeName];
        if (msg.sender != s.owner) {
            revert NotAuthorized(msg.sender);
        }
        s.operators[op] = false;
        emit ScopeRemoveOperator(scopeName, msg.sender, op);
    }

    /**
    @notice Set rules for a scope
    @param scopeName Name of the scope
    @param allowUserPatch Boolean indicating whether user patches are allowed
    @param allowUserAssign Boolean indicating whether user assignments are allowed
    @param requireWhitelist Boolean indicating whether whitelist is required
    */
    function setScopeRules(string calldata scopeName, bool allowUserPatch, bool allowUserAssign, bool requireWhitelist) public {
        Scope storage s = _scopes[scopeName];
        if (msg.sender != s.owner) {
            revert NotAuthorized(msg.sender);
        }
        s.allowUserPatch = allowUserPatch;
        s.allowUserAssign = allowUserAssign;
        s.requireWhitelist = requireWhitelist;
        emit ScopeRuleChange(scopeName, msg.sender, allowUserPatch, allowUserAssign, requireWhitelist);
    }

    /**
    @notice Add an address to a scope's whitelist
    @param scopeName Name of the scope
    @param addr Address to be whitelisted
    */
    function addWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _scopes[scopeName];
        if (msg.sender != s.owner && !s.operators[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }
        s.whitelist[addr] = true;
        emit ScopeWhitelistAdd(scopeName, msg.sender, addr);
    }

    /**
    @notice Remove an address from a scope's whitelist
    @param scopeName Name of the scope
    @param addr Address to be removed from the whitelist
    */
    function removeWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _scopes[scopeName];
        if (msg.sender != s.owner && !s.operators[msg.sender]) {
            revert NotAuthorized(msg.sender);
        }
        s.whitelist[addr] = false;
        emit ScopeWhitelistRemove(scopeName, msg.sender, addr);
    }

    /**
    @notice Create a new patch
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId Token ID of the original NFT
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function createPatch(address originalNFTAddress, uint originalNFTTokenId, address patchAddress) public returns (uint256 tokenId) {
        IPatchworkPatch patch = IPatchworkPatch(patchAddress);
        string memory scopeName = patch.getScopeName();
        // mint a Patch that is soulbound to the originalNFT using the contract address at patchAddress which must support Patchwork metadata
        Scope storage scope = _requireScope(scopeName);
        // TODO refactor to _checkWhitelist()
        if (scope.requireWhitelist && !scope.whitelist[patchAddress]) {
            revert NotWhitelisted(scopeName, patchAddress);
        }
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
    @notice Assigns an NFT relation to have an IPatchworkLiteRef form a LiteRef to a IPatchworkAssignableNFT
    @param fragment The IPatchworkAssignableNFT address to assign
    @param fragmentTokenId The IPatchworkAssignableNFT Token ID to assign
    @param target The IPatchworkLiteRef address to hold the reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID to hold the reference to the fragment
    */
    function assignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public {
        if (_checkFrozen(target, targetTokenId)) {
            revert Frozen(target, targetTokenId);
        }
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        uint64 ref = _doAssign(fragment, fragmentTokenId, target, targetTokenId, targetOwner);
        // call addReference on the target
        IPatchworkLiteRef(target).addReference(targetTokenId, ref);
    }

    /**
    @notice Assign multiple NFT fragments to a target NFT in batch
    @param fragments The array of addresses of the fragment IPatchworkAssignableNFTs
    @param tokenIds The array of token IDs of the fragment IPatchworkAssignableNFTs
    @param target The address of the target IPatchworkLiteRef NFT
    @param targetTokenId The token ID of the target IPatchworkLiteRef NFT
    */
    function batchAssignNFT(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) public {
        if (_checkFrozen(target, targetTokenId)) {
            revert Frozen(target, targetTokenId);
        }
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
    @notice Requires that scopeName is present
    @dev will revert with ScopeDoesNotExist if not present
    @return scope the scope
    */
    function _requireScope(string memory scopeName) private view returns (Scope storage scope) {
        Scope storage scope = _scopes[scopeName];
        if (scope.owner == address(0)) {
            revert ScopeDoesNotExist(scopeName);
        }
        return scope;
    }

    function _doAssign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, address targetOwner) private returns (uint64) {
        if (_checkFrozen(fragment, fragmentTokenId)) {
            revert Frozen(fragment, fragmentTokenId);
        }
        if (fragment == target && fragmentTokenId == targetTokenId) {
            revert SelfAssignmentNotAllowed(fragment, fragmentTokenId);
        }
        IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(fragment);
        if (_checkLocked(fragment, fragmentTokenId)) {
            revert Locked(fragment, fragmentTokenId);
        }
        // Use the fragment's scope for permissions, target already has to have fragment registered to be assignable
        string memory scopeName = assignableNFT.getScopeName();
        Scope storage scope = _requireScope(scopeName);
        // _checkWhitelist
        if (scope.requireWhitelist && !scope.whitelist[fragment]) {
            revert NotWhitelisted(scopeName, fragment);
        }
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
        (uint64 ref, bool redacted) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (ref == 0) {
            revert FragmentUnregistered(address(fragment));
        }
        if (redacted) {
            revert FragmentRedacted(address(fragment));
        }
        if (scope.liteRefs[ref]) {
            revert FragmentAlreadyAssignedInScope(scopeName, address(fragment), fragmentTokenId);
        }
        // call assign on the fragment
        assignableNFT.assign(fragmentTokenId, target, targetTokenId);
        // add to our storage of scope->target assignments
        scope.liteRefs[ref] = true;
        emit Assign(targetOwner, fragment, fragmentTokenId, target, targetTokenId);
        return ref;
    }

    /**
    @notice Unassign a NFT fragment from a target NFT
    @param fragment The IPatchworkAssignableNFT address of the fragment NFT
    @param fragmentTokenId The IPatchworkAssignableNFT token ID of the fragment NFT
    */
    function unassignNFT(address fragment, uint fragmentTokenId) public {
        if (_checkFrozen(fragment, fragmentTokenId)) {
            revert Frozen(fragment, fragmentTokenId);
        }
        IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(fragment);
        string memory scopeName = assignableNFT.getScopeName();
        Scope storage scope = _requireScope(scopeName);
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
        (address target, uint256 targetTokenId) = IPatchworkAssignableNFT(fragment).getAssignedTo(fragmentTokenId);
        if (target == address(0)) {
            revert FragmentNotAssigned(fragment, fragmentTokenId);
        }
        assignableNFT.unassign(fragmentTokenId);
        (uint64 ref, ) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        if (ref == 0) {
            revert FragmentUnregistered(address(fragment));
        }
        if (!scope.liteRefs[ref]) {
            revert RefNotFoundInScope(scopeName, target, fragment, fragmentTokenId);
        }
        scope.liteRefs[ref] = false;
        IPatchworkLiteRef(target).removeReference(targetTokenId, ref);
        emit Unassign(IERC721(target).ownerOf(targetTokenId), fragment, fragmentTokenId, target, targetTokenId);
    }

    /**
    @notice Apply transfer rules and actions of a specific token from one address to another
    @param from The address of the sender
    @param to The address of the receiver
    @param tokenId The ID of the token to be transferred
    */
    function applyTransfer(address from, address to, uint256 tokenId) public {
        address nft = msg.sender;
        if (IERC165(nft).supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE)) {
            IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(nft);
            (address addr,) = assignableNFT.getAssignedTo(tokenId);
            if (addr != address(0)) {
                revert TransferBlockedByAssignment(nft, tokenId);
            }
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKPATCH_INTERFACE)) {
            revert SoulboundTransferNotAllowed(nft, tokenId);
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKNFT_INTERFACE)) {
            if (IPatchworkNFT(nft).locked(tokenId)) {
                revert Locked(nft, tokenId);
            }
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKLITEREF_INTERFACE)) {
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i], nft, tokenId);
                }
            }
        }
    }

    function _applyAssignedTransfer(address nft, address from, address to, uint256 tokenId, address assignedToNFT_, uint256 assignedToTokenId_) internal {
        if (!IERC165(nft).supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE)) {
            revert NotPatchworkAssignable(nft);
        }
        (address assignedToNFT, uint256 assignedToTokenId) = IPatchworkAssignableNFT(nft).getAssignedTo(tokenId);
        // 2-way Check the assignment to prevent spoofing
        if (assignedToNFT_ != assignedToNFT || assignedToTokenId_ != assignedToTokenId) {
            revert DataIntegrityError(assignedToNFT_, assignedToTokenId_, assignedToNFT, assignedToTokenId);
        }
        IPatchworkAssignableNFT(nft).onAssignedTransfer(from, to, tokenId);
        if (IERC165(nft).supportsInterface(IPATCHWORKLITEREF_INTERFACE)) {
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

    // TODO rename to _isFrozen, add modifier to call and revert
    function _checkFrozen(address nft, uint256 tokenId) internal view returns (bool frozen) {
        if (IERC165(nft).supportsInterface(IPATCHWORKNFT_INTERFACE)) {
            if (IPatchworkNFT(nft).frozen(tokenId)) {
                return true;
            }
            if (IERC165(nft).supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE)) {
                (address assignedAddr, uint256 assignedTokenId) = IPatchworkAssignableNFT(nft).getAssignedTo(tokenId);
                if (assignedAddr != address(0)) {
                    return _checkFrozen(assignedAddr, assignedTokenId);
                }
            }
        }
        return false;
    }

    // TODO rename to _isLocked, see if modifier makes sense
    function _checkLocked(address nft, uint256 tokenId) internal view returns (bool locked) {
        if (IERC165(nft).supportsInterface(IPATCHWORKNFT_INTERFACE)) {
            if (IPatchworkNFT(nft).locked(tokenId)) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice Update the ownership tree of a specific Patchwork NFT
    @param nft The address of the Patchwork NFT
    @param tokenId The ID of the token whose ownership tree needs to be updated
    */
    function updateOwnershipTree(address nft, uint256 tokenId) public {
        if (IERC165(nft).supportsInterface(IPATCHWORKLITEREF_INTERFACE)) {
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    updateOwnershipTree(addresses[i], tokenIds[i]);
                }
            }
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE)) {
            IPatchworkAssignableNFT(nft).updateOwnership(tokenId);
        } else if (IERC165(nft).supportsInterface(IPATCHWORKPATCH_INTERFACE)) {
            IPatchworkPatch(nft).updateOwnership(tokenId);
        }
    }
}