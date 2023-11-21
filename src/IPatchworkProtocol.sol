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
    @param addr Address of the original 721
    @param tokenId ID of the patched token
    @param patchAddress Address of the patch applied
    */
    error AlreadyPatched(address addr, uint256 tokenId, address patchAddress);

    /**
    @notice The ERC1155 path has already been patched
    @param addr Address of the 1155
    @param tokenId ID of the patched token
    @param account The account patched
    @param patchAddress Address of the patch applied
    */
    error ERC1155AlreadyPatched(address addr, uint256 tokenId, address account, address patchAddress);

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
    @notice The reference was not found for the given fragment and target
    @param target Address of the target token
    @param fragment Address of the fragment
    @param tokenId ID of the fragment
    */
    error RefNotFound(address target, address fragment, uint256 tokenId);

    /**
    @notice The fragment with the provided ID at the given address is not assigned
    @param addr Address of the fragment
    @param tokenId ID of the fragment
    */
    error FragmentNotAssigned(address addr, uint256 tokenId);

    /**
    @notice The fragment with the provided ID at the given address is not assigned to the target
    @param addr Address of the fragment
    @param tokenId ID of the fragment
    @param targetAddress Address of the target
    @param targetTokenId ID of the target
    */
    error FragmentNotAssignedToTarget(address addr, uint256 tokenId, address targetAddress, uint256 targetTokenId);

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
    @notice The contract is not supported
    */
    error UnsupportedContract();

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
        @notice Mapped whitelist of addresses that belong to this scope
        @dev Address mapped to a boolean indicating if it's whitelisted
        */
        mapping(address => bool) whitelist;
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
    @notice Emitted when a patch is minted
    @param owner The owner of the patch
    @param originalAddress The address of the original NFT's contract
    @param originalTokenId The tokenId of the original NFT
    @param originalAccount The address of the original 1155's account
    @param patchAddress The address of the patch's contract
    @param patchTokenId The tokenId of the patch
    */
    event ERC1155Patch(address indexed owner, address originalAddress, uint256 originalTokenId, address originalAccount, address indexed patchAddress, uint256 indexed patchTokenId);


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
    event ScopeClaim(string scopeName, address indexed owner);

    /**
    @notice Emitted when a scope has elected a new owner to transfer to
    @param scopeName The name of the transferred scope
    @param from The owner of the scope
    @param to The owner-elect of the scope
    */
    event ScopeTransferElect(string scopeName, address indexed from, address indexed to);

    /**
    @notice Emitted when a scope transfer is canceled
    @param scopeName The name of the transferred scope
    @param from The owner of the scope
    @param to The owner-elect of the scope
    */
    event ScopeTransferCancel(string scopeName, address indexed from, address indexed to);

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
    function claimScope(string calldata scopeName) external;

    /**
    @notice Transfer ownership of a scope
    @dev must be accepted by transferee - see {acceptScopeTransfer}
    @param scopeName Name of the scope
    @param newOwner Address of the new owner
    */
    function transferScopeOwnership(string calldata scopeName, address newOwner) external;

    /**
    @notice Cancel a pending scope transfer
    @param scopeName Name of the scope
    */
    function cancelScopeTransfer(string calldata scopeName) external;

    /**
    @notice Accept a scope transfer
    @param scopeName Name of the scope
    */
    function acceptScopeTransfer(string calldata scopeName) external;

    /**
    @notice Get owner-elect of a scope
    @param scopeName Name of the scope
    @return ownerElect Address of the scope's owner-elect
    */
    function getScopeOwnerElect(string calldata scopeName) external returns (address ownerElect);

    /**
    @notice Get owner of a scope
    @param scopeName Name of the scope
    @return owner Address of the scope owner
    */
    function getScopeOwner(string calldata scopeName) external returns (address owner);

    /**
    @notice Add an operator to a scope
    @param scopeName Name of the scope
    @param op Address of the operator
    */
    function addOperator(string calldata scopeName, address op) external;

    /**
    @notice Remove an operator from a scope
    @param scopeName Name of the scope
    @param op Address of the operator
    */
    function removeOperator(string calldata scopeName, address op) external;

    /**
    @notice Set rules for a scope
    @param scopeName Name of the scope
    @param allowUserPatch Boolean indicating whether user patches are allowed
    @param allowUserAssign Boolean indicating whether user assignments are allowed
    @param requireWhitelist Boolean indicating whether whitelist is required
    */
    function setScopeRules(string calldata scopeName, bool allowUserPatch, bool allowUserAssign, bool requireWhitelist) external;

    /**
    @notice Add an address to a scope's whitelist
    @param scopeName Name of the scope
    @param addr Address to be whitelisted
    */
    function addWhitelist(string calldata scopeName, address addr) external;

    /**
    @notice Remove an address from a scope's whitelist
    @param scopeName Name of the scope
    @param addr Address to be removed from the whitelist
    */
    function removeWhitelist(string calldata scopeName, address addr) external;

    /**
    @notice Create a new patch
    @param owner The owner of the patch
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId Token ID of the original NFT
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function createPatch(address owner, address originalNFTAddress, uint originalNFTTokenId, address patchAddress) external returns (uint256 tokenId);

    /**
    @notice Create a new 1155 patch
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId Token ID of the original NFT
    @param originalAccount Address of the account to patch
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function create1155Patch(address to, address originalNFTAddress, uint originalNFTTokenId, address originalAccount, address patchAddress) external returns (uint256 tokenId);
    
    /**
    @notice Create a new account patch
    @param owner The owner of the patch
    @param originalAddress Address of the original account
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function createAccountPatch(address owner, address originalAddress, address patchAddress) external returns (uint256 tokenId);

    /**
    @notice Assigns an NFT relation to have an IPatchworkLiteRef form a LiteRef to a IPatchworkAssignableNFT
    @param fragment The IPatchworkAssignableNFT address to assign
    @param fragmentTokenId The IPatchworkAssignableNFT Token ID to assign
    @param target The IPatchworkLiteRef address to hold the reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID to hold the reference to the fragment
    */
    function assignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) external;

    /**
    @notice Assigns an NFT relation to have an IPatchworkLiteRef form a LiteRef to a IPatchworkAssignableNFT
    @param fragment The IPatchworkAssignableNFT address to assign
    @param fragmentTokenId The IPatchworkAssignableNFT Token ID to assign
    @param target The IPatchworkLiteRef address to hold the reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID to hold the reference to the fragment
    @param targetMetadataId The metadata ID on the target NFT to store the reference in
    */
    function assignNFTDirect(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) external;

    /**
    @notice Assign multiple NFT fragments to a target NFT in batch
    @param fragments The array of addresses of the fragment IPatchworkAssignableNFTs
    @param tokenIds The array of token IDs of the fragment IPatchworkAssignableNFTs
    @param target The address of the target IPatchworkLiteRef NFT
    @param targetTokenId The token ID of the target IPatchworkLiteRef NFT
    */
    function batchAssignNFT(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) external;

    /**
    @notice Assign multiple NFT fragments to a target NFT in batch
    @param fragments The array of addresses of the fragment IPatchworkAssignableNFTs
    @param tokenIds The array of token IDs of the fragment IPatchworkAssignableNFTs
    @param target The address of the target IPatchworkLiteRef NFT
    @param targetTokenId The token ID of the target IPatchworkLiteRef NFT
    @param targetMetadataId The metadata ID on the target NFT to store the references in
    */
    function batchAssignNFTDirect(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId, uint256 targetMetadataId) external;

    /**
    @notice Unassign a NFT fragment from a target NFT
    @param fragment The IPatchworkSingleAssignableNFT address of the fragment NFT
    @param fragmentTokenId The IPatchworkSingleAssignableNFT token ID of the fragment NFT
    @dev reverts if fragment is not an IPatchworkSingleAssignableNFT
    */
    function unassignSingleNFT(address fragment, uint fragmentTokenId) external;

    /**
    @notice Unassigns a multi NFT relation
    @param fragment The IPatchworMultiAssignableNFT address to unassign
    @param fragmentTokenId The IPatchworkMultiAssignableNFT Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    @dev reverts if fragment is not an IPatchworkMultiAssignableNFT
    */
    function unassignMultiNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) external;

    /**
    @notice Unassigns an NFT relation (single or multi)
    @param fragment The IPatchworkAssignableNFT address to unassign
    @param fragmentTokenId The IPatchworkAssignableNFT Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    */
    function unassignNFT(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) external;

    /**
    @notice Unassign a NFT fragment from a target NFT
    @param fragment The IPatchworkSingleAssignableNFT address of the fragment NFT
    @param fragmentTokenId The IPatchworkSingleAssignableNFT token ID of the fragment NFT
    @param targetMetadataId The metadata ID on the target NFT to unassign from
    @dev reverts if fragment is not an IPatchworkSingleAssignableNFT
    */
    function unassignSingleNFTDirect(address fragment, uint fragmentTokenId, uint256 targetMetadataId) external;

    /**
    @notice Unassigns a multi NFT relation
    @param fragment The IPatchworMultiAssignableNFT address to unassign
    @param fragmentTokenId The IPatchworkMultiAssignableNFT Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    @param targetMetadataId The metadata ID on the target NFT to unassign from
    @dev reverts if fragment is not an IPatchworkMultiAssignableNFT
    */
    function unassignMultiNFTDirect(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) external;

    /**
    @notice Unassigns an NFT relation (single or multi)
    @param fragment The IPatchworkAssignableNFT address to unassign
    @param fragmentTokenId The IPatchworkAssignableNFT Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    @param targetMetadataId The metadata ID on the target NFT to unassign from
    */
    function unassignNFTDirect(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) external;

    /**
    @notice Apply transfer rules and actions of a specific token from one address to another
    @param from The address of the sender
    @param to The address of the receiver
    @param tokenId The ID of the token to be transferred
    */
    function applyTransfer(address from, address to, uint256 tokenId) external;

    /**
    @notice Update the ownership tree of a specific Patchwork NFT
    @param nft The address of the Patchwork NFT
    @param tokenId The ID of the token whose ownership tree needs to be updated
    */
    function updateOwnershipTree(address nft, uint256 tokenId) external;
}