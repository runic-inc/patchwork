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

    /**
    @notice The address is not authorized to perform this action
    @param addr The address attempting to perform the action
    */
    error NotAuthorized(address addr);

    /**
    @notice The scope with the provided name already exists
    @param scopeName Name of the scope
    */
    error ScopeExists(string scopeName);

    /**
    @notice The scope with the provided name does not exist
    @param scopeName Name of the scope
    */
    error ScopeDoesNotExist(string scopeName);

    /**
    @notice Transfer of the scope to the provided address is not allowed
    @param to Address not allowed for scope transfer
    */
    error ScopeTransferNotAllowed(address to);

    /**
    @notice The token with the provided ID at the given address is frozen
    @param addr Address of the token owner
    @param tokenId ID of the frozen token
    */
    error Frozen(address addr, uint256 tokenId);

    /**
    @notice The token with the provided ID at the given address is locked
    @param addr Address of the token owner
    @param tokenId ID of the locked token
    */
    error Locked(address addr, uint256 tokenId);

    /**
    @notice The address is not whitelisted for the given scope
    @param scopeName Name of the scope
    @param addr Address that isn't whitelisted
    */
    error NotWhitelisted(string scopeName, address addr);

    /**
    @notice The token at the given address has already been patched
    @param addr Address of the token owner
    @param tokenId ID of the patched token
    @param patchAddress Address of the patch applied
    */
    error AlreadyPatched(address addr, uint256 tokenId, address patchAddress);

    /**
    @notice The provided input lengths are not compatible or valid
    @dev for any multi array inputs, they must be the same length
    */
    error BadInputLengths();

    /**
    @notice The fragment at the given address is unregistered
    @param addr Address of the unregistered fragment
    */
    error FragmentUnregistered(address addr);

    /**
    @notice The fragment at the given address has been redacted
    @param addr Address of the redacted fragment
    */
    error FragmentRedacted(address addr);

    /**
    @notice The fragment with the provided ID at the given address is already assigned
    @param addr Address of the fragment
    @param tokenId ID of the assigned fragment
    */
    error FragmentAlreadyAssigned(address addr, uint256 tokenId);

    /**
    @notice The fragment with the provided ID at the given address is already assigned in the scope
    @param scopeName Name of the scope
    @param addr Address of the fragment
    @param tokenId ID of the fragment
    */
    error FragmentAlreadyAssignedInScope(string scopeName, address addr, uint256 tokenId);

    /**
    @notice The reference was not found in the scope for the given fragment and target
    @param scopeName Name of the scope
    @param target Address of the target token
    @param fragment Address of the fragment
    @param tokenId ID of the fragment
    */
    error RefNotFoundInScope(string scopeName, address target, address fragment, uint256 tokenId);

    /**
    @notice The fragment with the provided ID at the given address is not assigned
    @param addr Address of the fragment
    @param tokenId ID of the fragment
    */
    error FragmentNotAssigned(address addr, uint256 tokenId);

    /**
    @notice The fragment at the given address is already registered
    @param addr Address of the registered fragment
    */
    error FragmentAlreadyRegistered(address addr);

    /**
    @notice Ran out of available IDs for allocation
    @dev Max 255 IDs per NFT
    */
    error OutOfIDs();

    /**
    @notice The provided token ID is unsupported
    @dev TokenIds may only be 56 bits long
    @param tokenId The unsupported token ID
    */
    error UnsupportedTokenId(uint256 tokenId);

    /**
    @notice Cannot lock the soulbound patch at the given address
    @param addr Address of the soulbound patch
    */
    error CannotLockSoulboundPatch(address addr);

    /**
    @notice The token with the provided ID at the given address is not frozen
    @param addr Address of the token owner
    @param tokenId ID of the token
    */
    error NotFrozen(address addr, uint256 tokenId);

    /**
    @notice The nonce for the token with the provided ID at the given address is incorrect
    @dev It may be incorrect or a newer nonce may be present
    @param addr Address of the token owner
    @param tokenId ID of the token
    @param nonce The incorrect nonce
    */
    error IncorrectNonce(address addr, uint256 tokenId, uint256 nonce);

    /**
    @notice Self assignment of the token with the provided ID at the given address is not allowed
    @param addr Address of the token owner
    @param tokenId ID of the token
    */
    error SelfAssignmentNotAllowed(address addr, uint256 tokenId);

    /**
    @notice Transfer of the soulbound token with the provided ID at the given address is not allowed
    @param addr Address of the token owner
    @param tokenId ID of the token
    */
    error SoulboundTransferNotAllowed(address addr, uint256 tokenId);

    /**
    @notice Transfer of the token with the provided ID at the given address is blocked by an assignment
    @param addr Address of the token owner
    @param tokenId ID of the token
    */
    error TransferBlockedByAssignment(address addr, uint256 tokenId);

    /**
    @notice The token at the given address is not IPatchworkAssignable
    @param addr Address of the non-assignable token
    */
    error NotPatchworkAssignable(address addr);

    /**
    @notice A data integrity error has been detected
    @dev Addr+TokenId is expected where addr2+tokenId2 is present
    @param addr Address of the first token
    @param tokenId ID of the first token
    @param addr2 Address of the second token
    @param tokenId2 ID of the second token
    */
    error DataIntegrityError(address addr, uint256 tokenId, address addr2, uint256 tokenId2);

    /**
    @notice Represents a defined scope within the system
    @dev Contains details about the scope ownership, permissions, and mappings for references and assignments
    */
    struct Scope {
        /**
        @notice Owner of this scope
        @dev Address of the account or contract that owns this scope
        */
        address owner;

        /**
        @notice Indicates whether a user is allowed to patch within this scope
        @dev True if a user can patch, false otherwise. If false, only operators and the scope owner can perform patching.
        */
        bool allowUserPatch;

        /**
        @notice Indicates whether a user is allowed to assign within this scope
        @dev True if a user can assign, false otherwise. If false, only operators and the scope owner can perform assignments.
        */
        bool allowUserAssign;

        /**
        @notice Indicates if a whitelist is required for operations within this scope
        @dev True if whitelist is required, false otherwise
        */
        bool requireWhitelist;

        /**
        @notice Mapped list of operator addresses for this scope
        @dev Address of the operator mapped to a boolean indicating if they are an operator
        */
        mapping(address => bool) operators;

        /**
        @notice Mapped list of lightweight references within this scope
        // TODO: A unique hash of liteRefAddr + reference will be needed for uniqueness
        */
        mapping(uint64 => bool) liteRefs;

        /**
        @notice Mapped whitelist of addresses that belong to this scope
        @dev Address mapped to a boolean indicating if it's whitelisted
        */
        mapping(address => bool) whitelist;

        /**
        @notice Mapped list of unique patches associated with this scope
        @dev Hash of the patch mapped to a boolean indicating its uniqueness
        */
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
    event ScopeClaim(string scopeName, address indexed owner);

    /**
    @notice Emitted when a scope is transferred
    @param scopeName The name of the transferred scope
    @param from The address transferring the scope
    @param to The recipient of the scope
    */
    event ScopeTransfer(string scopeName, address indexed from, address indexed to);

    /**
    @notice Emitted when a scope has an operator added
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param operator The new operator's address
    */
    event ScopeAddOperator(string scopeName, address indexed actor, address indexed operator);

    /**
    @notice Emitted when a scope has an operator removed
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param operator The operator's address being removed
    */
    event ScopeRemoveOperator(string scopeName, address indexed actor, address indexed operator);

    /**
    @notice Emitted when a scope's rules are changed
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param allowUserPatch Indicates whether user patches are allowed
    @param allowUserAssign Indicates whether user assignments are allowed
    @param requireWhitelist Indicates whether a whitelist is required
    */
    event ScopeRuleChange(string scopeName, address indexed actor, bool allowUserPatch, bool allowUserAssign, bool requireWhitelist);

    /**
    @notice Emitted when a scope has an address added to the whitelist
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param addr The address being added to the whitelist
    */
    event ScopeWhitelistAdd(string scopeName, address indexed actor, address indexed addr);

    /**
    @notice Emitted when a scope has an address removed from the whitelist
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param addr The address being removed from the whitelist
    */
    event ScopeWhitelistRemove(string scopeName, address indexed actor, address indexed addr);

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
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
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
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
        s.operators[op] = true;
        emit ScopeAddOperator(scopeName, msg.sender, op);
    }

    /**
    @notice Remove an operator from a scope
    @param scopeName Name of the scope
    @param op Address of the operator
    */
    function removeOperator(string calldata scopeName, address op) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
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
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwner(s);
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
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(s);
        s.whitelist[addr] = true;
        emit ScopeWhitelistAdd(scopeName, msg.sender, addr);
    }

    /**
    @notice Remove an address from a scope's whitelist
    @param scopeName Name of the scope
    @param addr Address to be removed from the whitelist
    */
    function removeWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _mustHaveScope(scopeName);
        _mustBeOwnerOrOperator(s);
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
    @notice Assigns an NFT relation to have an IPatchworkLiteRef form a LiteRef to a IPatchworkAssignableNFT
    @param fragment The IPatchworkAssignableNFT address to assign
    @param fragmentTokenId The IPatchworkAssignableNFT Token ID to assign
    @param target The IPatchworkLiteRef address to hold the reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID to hold the reference to the fragment
    */
    function assignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) public mustNotBeFrozen(target, targetTokenId) {
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
        // reduce stack to stay under limit
        uint64 ref;
        {
            (uint64 _ref, bool redacted) = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
            ref = _ref;
            if (ref == 0) {
                revert FragmentUnregistered(address(fragment));
            }
            if (redacted) {
                revert FragmentRedacted(address(fragment));
            }
            if (scope.liteRefs[ref]) {
                revert FragmentAlreadyAssignedInScope(scopeName, address(fragment), fragmentTokenId);
            }
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
    function unassignNFT(address fragment, uint fragmentTokenId) public mustNotBeFrozen(fragment, fragmentTokenId) {
        IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(fragment);
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
        if (IERC165(nft).supportsInterface(type(IPatchworkAssignableNFT).interfaceId)) {
            IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(nft);
            (address addr,) = assignableNFT.getAssignedTo(tokenId);
            if (addr != address(0)) {
                revert TransferBlockedByAssignment(nft, tokenId);
            }
        }
        if (IERC165(nft).supportsInterface(type(IPatchworkPatch).interfaceId)) {
            revert SoulboundTransferNotAllowed(nft, tokenId);
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
        if (!IERC165(nft).supportsInterface(type(IPatchworkAssignableNFT).interfaceId)) {
            revert NotPatchworkAssignable(nft);
        }
        (address assignedToNFT, uint256 assignedToTokenId) = IPatchworkAssignableNFT(nft).getAssignedTo(tokenId);
        // 2-way Check the assignment to prevent spoofing
        if (assignedToNFT_ != assignedToNFT || assignedToTokenId_ != assignedToTokenId) {
            revert DataIntegrityError(assignedToNFT_, assignedToTokenId_, assignedToNFT, assignedToTokenId);
        }
        IPatchworkAssignableNFT(nft).onAssignedTransfer(from, to, tokenId);
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
    @notice Update the ownership tree of a specific Patchwork NFT
    @param nft The address of the Patchwork NFT
    @param tokenId The ID of the token whose ownership tree needs to be updated
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
        if (IERC165(nft).supportsInterface(type(IPatchworkAssignableNFT).interfaceId)) {
            IPatchworkAssignableNFT(nft).updateOwnership(tokenId);
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
            if (IERC165(nft).supportsInterface(type(IPatchworkAssignableNFT).interfaceId)) {
                (address assignedAddr, uint256 assignedTokenId) = IPatchworkAssignableNFT(nft).getAssignedTo(tokenId);
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