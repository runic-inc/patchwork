// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
@title Patchwork Protocol Interface
@author Runic Labs, Inc
@notice Interface for Patchwork Protocol
*/
interface IPatchworkProtocol {
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
    @notice The address at the given address has already been patched
    @param addr The address that was patched
    @param patchAddress Address of the patch applied
    */
    error AccountAlreadyPatched(address addr, address patchAddress);

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
    @notice Transfer of the token with the provided ID at the given address is not allowed
    @param addr Address of the token owner
    @param tokenId ID of the token
    */
    error TransferNotAllowed(address addr, uint256 tokenId);

    /**
    @notice Transfer of the token with the provided ID at the given address is blocked by an assignment
    @param addr Address of the token owner
    @param tokenId ID of the token
    */
    error TransferBlockedByAssignment(address addr, uint256 tokenId);

    /**
    @notice A rule is blocking the mint to this owner address
    @param addr Address of the token owner
    */
    error MintNotAllowed(address addr);

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
    @notice The operation is not supported
    */
    error UnsupportedOperation();

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
        @notice Owner-elect
        @dev Used in two-step transfer process. If this is set, only this owner can accept the transfer
        */
        address ownerElect;

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
        @dev A hash of liteRefAddr + reference provides uniqueness
        */
        mapping(bytes32 => bool) liteRefs;

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
    @notice Emitted when an account patch is minted
    @param owner The owner of the patch
    @param originalAddress The address of the original NFT's contract
    @param patchAddress The address of the patch's contract
    @param patchTokenId The tokenId of the patch
    */
    event AccountPatch(address indexed owner, address originalAddress, address indexed patchAddress, uint256 indexed patchTokenId);

    /**
    @notice Emitted when a new scope is claimed
    @param scopeName The name of the claimed scope
    @param owner The owner of the scope
    */
    event ScopeClaim(string indexed scopeName, address indexed owner);

    /**
    @notice Emitted when a scope has elected a new owner to transfer to
    @param scopeName The name of the transferred scope
    @param from The owner of the scope
    @param to The owner-elect of the scope
    */
    event ScopeTransferElect(string indexed scopeName, address indexed from, address indexed to);

    /**
    @notice Emitted when a scope transfer is canceled
    @param scopeName The name of the transferred scope
    @param from The owner of the scope
    @param to The owner-elect of the scope
    */
    event ScopeTransferCancel(string indexed scopeName, address indexed from, address indexed to);

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
}