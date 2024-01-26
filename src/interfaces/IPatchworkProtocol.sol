// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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
    @dev Max 255 IDs per target
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
    @notice The available balance does not satisfy the amount
    */
    error InsufficientFunds();

    /**
    @notice The supplied fee is not the corret amount
    */
    error IncorrectFeeAmount();

    /**
    @notice Minting is not active for this address 
    */
    error MintNotActive();

    /**
    @notice The value could not be sent 
    */
    error FailedToSend();   
    
    /**
    @notice The contract is not supported
    */
    error UnsupportedContract();
    
    /**
    @notice The operation is not supported
    */
    error UnsupportedOperation();

    /**
    @notice No proposed fee is set 
    */
    error NoProposedFeeSet();

    /**
    @notice Timelock has not elapsed
    */
    error TimelockNotElapsed();

    /**
    @notice Invalid fee value 
    */
    error InvalidFeeValue();

    /**
    @notice No delegate proposed 
    */
    error NoDelegateProposed();
    
    /** 
    @notice Fee Configuration
    */
    struct FeeConfig {
        uint256 mintBp;   /// mint basis points (10000 = 100%)
        uint256 patchBp;  /// patch basis points (10000 = 100%)
        uint256 assignBp; /// assign basis points (10000 = 100%)
    }

    /** 
    @notice Fee Configuration Override
    */
    struct FeeConfigOverride {
        uint256 mintBp;   /// mint basis points (10000 = 100%)
        uint256 patchBp;  /// patch basis points (10000 = 100%)
        uint256 assignBp; /// assign basis points (10000 = 100%)
        bool active; /// true for present
    }

    /**
    @notice Proposal to change a fee configuration for either protocol or scope override
    */
    struct ProposedFeeConfig {
        FeeConfig config;
        uint256 timestamp;
        bool active; /// Used to enable/disable overrides - ignored for protocol
    }

    /**
    @notice Mint configuration
    */
    struct MintConfig {
        uint256 flatFee; /// fee per 1 quantity mint in wei
        bool active;     /// If the mint is active
    }

    /**
    @notice Proposed assigner delegate
    */
    struct ProposedAssignerDelegate {
        uint256 timestamp;
        address addr;
    }

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

        /**
        @notice Mapped list of mint configurations for this scope
        @dev Address of the IPatchworkMintable mapped to the configuration
        */
        mapping(address => MintConfig) mintConfigurations;

        /**
        @notice Mapped list of patch fees for this scope
        @dev Address of a 721, 1155 or account patch mapped to the fee in wei 
        */
        mapping(address => uint256) patchFees;

        /**
        @notice Mapped list of assign fees for this scope
        @dev Address of an IPatchworkAssignable mapped to the fee in wei 
        */        
        mapping(address => uint256) assignFees;

        /**
        @notice Balance in wei for this scope
        @dev accrued in mint, patch and assign fees, may only be withdrawn by scope bankers
        */
        uint256 balance;

        /**
        @notice Mapped list of addresses that are designated bankers for this scope 
        @dev Address mapped to a boolean indicating if they are a banker
        */
        mapping(address => bool) bankers;
    }

    /**
    @notice Emitted when a fragment is assigned
    @param owner The owner of the target and fragment
    @param fragmentAddress The address of the fragment's contract
    @param fragmentTokenId The tokenId of the fragment
    @param targetAddress The address of the target's contract
    @param targetTokenId The tokenId of the target
    @param scopeFee The fee collected to the scope
    @param protocolFee The fee collected to the protocol
    */
    event Assign(address indexed owner, address fragmentAddress, uint256 fragmentTokenId, address indexed targetAddress, uint256 indexed targetTokenId, uint256 scopeFee, uint256 protocolFee);

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
    @param originalAddress The address of the original 721's contract
    @param originalTokenId The tokenId of the original 721
    @param patchAddress The address of the patch's contract
    @param patchTokenId The tokenId of the patch
    @param scopeFee The fee collected to the scope
    @param protocolFee The fee collected to the protocol
    */
    event Patch(address indexed owner, address originalAddress, uint256 originalTokenId, address indexed patchAddress, uint256 indexed patchTokenId, uint256 scopeFee, uint256 protocolFee);

    /**
    @notice Emitted when a patch is minted
    @param owner The owner of the patch
    @param originalAddress The address of the original 1155's contract
    @param originalTokenId The tokenId of the original 1155
    @param originalAccount The address of the original 1155's account
    @param patchAddress The address of the patch's contract
    @param patchTokenId The tokenId of the patch
    @param scopeFee The fee collected to the scope
    @param protocolFee The fee collected to the protocol
    */
    event ERC1155Patch(address indexed owner, address originalAddress, uint256 originalTokenId, address originalAccount, address indexed patchAddress, uint256 indexed patchTokenId, uint256 scopeFee, uint256 protocolFee);


    /**
    @notice Emitted when an account patch is minted
    @param owner The owner of the patch
    @param originalAddress The address of the original account
    @param patchAddress The address of the patch's contract
    @param patchTokenId The tokenId of the patch
    @param scopeFee The fee collected to the scope
    @param protocolFee The fee collected to the protocol
    */
    event AccountPatch(address indexed owner, address originalAddress, address indexed patchAddress, uint256 indexed patchTokenId, uint256 scopeFee, uint256 protocolFee);

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
    @notice Emitted when a mint is configured
    @param scopeName The name of the scope
    @param mintable The address of the IPatchworkMintable
    @param config The mint configuration
    */
    event MintConfigure(string scopeName, address indexed actor, address indexed mintable, MintConfig config);

    /**
    @notice Emitted when a banker is added to a scope
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param banker The banker that was added
    */
    event ScopeBankerAdd(string scopeName, address indexed actor, address indexed banker);

    /**
    @notice Emitted when a banker is removed from a scope
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param banker The banker that was removed
    */
    event ScopeBankerRemove(string scopeName, address indexed actor, address indexed banker);
    
    /**
    @notice Emitted when a withdrawl is made from a scope
    @param scopeName The name of the scope
    @param actor The address responsible for the action
    @param amount The amount withdrawn
    */    
    event ScopeWithdraw(string scopeName, address indexed actor, uint256 amount);

    /**
    @notice Emitted when a banker is added to the protocol
    @param actor The address responsible for the action
    @param banker The banker that was added
    */
    event ProtocolBankerAdd(address indexed actor, address indexed banker);

    /**
    @notice Emitted when a banker is removed from the protocol
    @param actor The address responsible for the action
    @param banker The banker that was removed
    */
    event ProtocolBankerRemove(address indexed actor, address indexed banker);

    /**
    @notice Emitted when a withdrawl is made from the protocol
    @param actor The address responsible for the action
    @param amount The amount withdrawn
    */
    event ProtocolWithdraw(address indexed actor, uint256 amount);

    /**
    @notice Emitted on mint
    @param actor The address responsible for the action
    @param scopeName The scope of the IPatchworkMintable
    @param to The receipient of the mint
    @param mintable The IPatchworkMintable minted
    @param data The data used to mint
    @param scopeFee The fee collected to the scope
    @param protocolFee The fee collected to the protocol
    */
    event Mint(address indexed actor, string scopeName, address indexed to, address indexed mintable, bytes data, uint256 scopeFee, uint256 protocolFee);

    /**
    @notice Emitted on batch mint
    @param actor The address responsible for the action
    @param scopeName The scope of the IPatchworkMintable
    @param to The receipient of the mint
    @param mintable The IPatchworkMintable minted
    @param data The data used to mint
    @param quantity The quantity minted
    @param scopeFee The fee collected to the scope
    @param protocolFee The fee collected to the protocol
    */
    event MintBatch(address indexed actor, string scopeName, address indexed to, address indexed mintable, bytes data, uint256 quantity, uint256 scopeFee, uint256 protocolFee);

    /**
    @notice Emitted on protocol fee config proposed
    @param config The fee configuration
    */
    event ProtocolFeeConfigPropose(FeeConfig config);

    /**
    @notice Emitted on protocol fee config committed
    @param config The fee configuration
    */
    event ProtocolFeeConfigCommit(FeeConfig config);

    /**
    @notice Emitted on scope fee config override proposed
    @param scopeName The scope
    @param config The fee configuration
    */
    event ScopeFeeOverridePropose(string scopeName, FeeConfigOverride config);

    /**
    @notice Emitted on scope fee config override committed
    @param scopeName The scope
    @param config The fee configuration
    */
    event ScopeFeeOverrideCommit(string scopeName, FeeConfigOverride config);

    /**
    @notice Emitted on patch fee change
    @param scopeName The scope of the patch
    @param addr The address of the patch
    @param fee The new fee
    */
    event PatchFeeChange(string scopeName, address indexed addr, uint256 fee);

    /**
    @notice Emitted on assign fee change 
    @param scopeName The scope of the assignable
    @param addr The address of the assignable
    @param fee The new fee
    */
    event AssignFeeChange(string scopeName, address indexed addr, uint256 fee);

    /**
    @notice Emitted on assigner delegate propose
    @param addr The address of the delegate
    */
    event AssignerDelegatePropose(address indexed addr);

    /**
    @notice Emitted on assigner delegate commit
    @param addr The address of the delegate
    */
    event AssignerDelegateCommit(address indexed addr);

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
    function getScopeOwnerElect(string calldata scopeName) external view returns (address ownerElect);

    /**
    @notice Get owner of a scope
    @param scopeName Name of the scope
    @return owner Address of the scope owner
    */
    function getScopeOwner(string calldata scopeName) external view returns (address owner);

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
    @notice Set the mint configuration for a given address
    @param addr The address for which to set the mint configuration, must be IPatchworkMintable
    @param config The mint configuration to be set
    */
    function setMintConfiguration(address addr, MintConfig memory config) external;

    /**
    @notice Get the mint configuration for a given address
    @param addr The address for which to get the mint configuration
    @return config The mint configuration of the given address
    */
    function getMintConfiguration(address addr) external view returns (MintConfig memory config);

    /**
    @notice Set the patch fee for a given address
    @dev must be banker of scope claimed by addr to call
    @param addr The address for which to set the patch fee
    @param baseFee The patch fee to be set in wei
    */
    function setPatchFee(address addr, uint256 baseFee) external;

    /**
    @notice Get the patch fee for a given address
    @param addr The address for which to get the patch fee
    @return baseFee The patch fee of the given address in wei
    */
    function getPatchFee(address addr) external view returns (uint256 baseFee);

    /**
    @notice Set the assign fee for a given fragment address
    @dev must be banker of scope claimed by fragmentAddress to call
    @param fragmentAddress The address of the fragment for which to set the fee
    @param baseFee The assign fee to be set in wei
    */
    function setAssignFee(address fragmentAddress, uint256 baseFee) external;

    /**
    @notice Get the assign fee for a given fragment address
    @param fragmentAddress The address of the fragment for which to get the fee
    @return baseFee The assign fee of the given fragment address in wei
    */
    function getAssignFee(address fragmentAddress) external view returns (uint256 baseFee);

    /**
    @notice Add a banker to a given scope
    @dev must be owner of scope to call
    @param scopeName The name of the scope
    @param addr The address to be added as a banker
    */
    function addBanker(string memory scopeName, address addr) external;

    /**
    @notice Remove a banker from a given scope
    @dev must be owner of scope to call
    @param scopeName The name of the scope
    @param addr The address to be removed as a banker
    */
    function removeBanker(string memory scopeName, address addr) external;

    /**
    @notice Withdraw an amount from the balance of a given scope
    @dev must be owner of scope or banker of scope to call
    @dev transfers to the msg.sender
    @param scopeName The name of the scope
    @param amount The amount to be withdrawn in wei
    */
    function withdraw(string memory scopeName, uint256 amount) external;

    /**
    @notice Get the balance of a given scope
    @param scopeName The name of the scope
    @return balance The balance of the given scope in wei
    */
    function balanceOf(string memory scopeName) external view returns (uint256 balance);

    /**
    @notice Mint a new token
    @param to The address to which the token will be minted
    @param mintable The address of the IPatchworkMintable contract
    @param data Additional data to be passed to the minting
    @return tokenId The ID of the minted token
    */
    function mint(address to, address mintable, bytes calldata data) external payable returns (uint256 tokenId);

    /**
    @notice Mint a batch of new tokens
    @param to The address to which the tokens will be minted
    @param mintable The address of the IPatchworkMintable contract
    @param data Additional data to be passed to the minting
    @param quantity The number of tokens to mint
    @return tokenIds An array of the IDs of the minted tokens
    */
    function mintBatch(address to, address mintable, bytes calldata data, uint256 quantity) external payable returns (uint256[] memory tokenIds);

    /**
    @notice Proposes a protocol fee configuration
    @dev must be protocol owner or banker to call
    @dev configuration does not apply until commitProtocolFeeConfig is called
    @param config The protocol fee configuration to be set
    */
    function proposeProtocolFeeConfig(FeeConfig memory config) external;

    /**
    @notice Commits the current proposed protocol fee configuration
    @dev must be protocol owner or banker to call
    @dev may only be called after timelock has passed
    */
    function commitProtocolFeeConfig() external;

    /**
    @notice Get the current protocol fee configuration
    @return config The current protocol fee configuration
    */
    function getProtocolFeeConfig() external view returns (FeeConfig memory config);

    /**
    @notice Proposes a protocol fee override for a scope
    @dev must be protocol owner or banker to call
    @param config The protocol fee override configuration to be set
    */
    function proposeScopeFeeOverride(string memory scopeName, FeeConfigOverride memory config) external;

    /**
    @notice Commits the current proposed protocol fee override configuration for a scope
    @dev must be protocol owner or banker to call
    @dev may only be called after timelock has passed
    */
    function commitScopeFeeOverride(string memory scopeName) external;

    /**
    @notice Get the protocol fee override for a scope
    @return config The current protocol fee override
    */
    function getScopeFeeOverride(string memory scopeName) external view returns (FeeConfigOverride memory config);

    /**
    @notice Add a banker to the protocol
    @dev must be protocol owner to call
    @param addr The address to be added as a protocol banker
    */
    function addProtocolBanker(address addr) external;

    /**
    @notice Remove a banker from the protocol
    @dev must be protocol owner to call
    @param addr The address to be removed as a protocol banker
    */
    function removeProtocolBanker(address addr) external;

    /**
    @notice Withdraw a specified amount from the protocol balance
    @dev must be protocol owner or banker to call
    @dev transfers to the msg.sender
    @param balance The amount to be withdrawn in wei
    */
    function withdrawFromProtocol(uint256 balance) external;

    /**
    @notice Get the current balance of the protocol
    @return balance The balance of the protocol in wei
    */
    function balanceOfProtocol() external view returns (uint256 balance);

    /**
    @notice Create a new patch
    @param owner The owner of the patch
    @param originalAddress Address of the original 721
    @param originalTokenId Token ID of the original 721
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function patch(address owner, address originalAddress, uint originalTokenId, address patchAddress) external payable returns (uint256 tokenId);

    /**
    @notice Callback for when a patch is burned
    @dev can only be called from the patchAddress
    @param originalAddress Address of the original 721
    @param originalTokenId Token ID of the original 721
    @param patchAddress Address of the IPatchworkPatch to mint
    */
    function patchBurned(address originalAddress, uint originalTokenId, address patchAddress) external;

    /**
    @notice Create a new 1155 patch
    @param originalAddress Address of the original 1155
    @param originalTokenId Token ID of the original 1155
    @param originalAccount Address of the account to patch
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function patch1155(address to, address originalAddress, uint originalTokenId, address originalAccount, address patchAddress) external payable returns (uint256 tokenId);
    
    /**
    @notice Callback for when an 1155 patch is burned
    @dev can only be called from the patchAddress
    @param originalAddress Address of the original 1155
    @param originalTokenId Token ID of the original 1155
    @param originalAccount Address of the account to patch
    @param patchAddress Address of the IPatchworkPatch to mint
    */
    function patchBurned1155(address originalAddress, uint originalTokenId, address originalAccount, address patchAddress) external;

    /**
    @notice Create a new account patch
    @param owner The owner of the patch
    @param originalAddress Address of the original account
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function patchAccount(address owner, address originalAddress, address patchAddress) external payable returns (uint256 tokenId);

    /**
    @notice Callback for when an account patch is burned
    @dev can only be called from the patchAddress
    @param originalAddress Address of the original 1155
    @param patchAddress Address of the IPatchworkPatch to mint
    */
    function patchBurnedAccount(address originalAddress, address patchAddress) external;

    /**
    @notice Assigns a relation to have an IPatchworkLiteRef form a LiteRef to a IPatchworkAssignable
    @param fragment The IPatchworkAssignable address to assign
    @param fragmentTokenId The IPatchworkAssignable Token ID to assign
    @param target The IPatchworkLiteRef address to hold the reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID to hold the reference to the fragment
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) external payable;

    /**
    @notice Assigns a relation to have an IPatchworkLiteRef form a LiteRef to a IPatchworkAssignable
    @param fragment The IPatchworkAssignable address to assign
    @param fragmentTokenId The IPatchworkAssignable Token ID to assign
    @param target The IPatchworkLiteRef address to hold the reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID to hold the reference to the fragment
    @param targetMetadataId The metadata ID on the target to store the reference in
    */
    function assign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) external payable;

    /**
    @notice Assign multiple fragments to a target in batch
    @param fragments The array of addresses of the fragment IPatchworkAssignables
    @param tokenIds The array of token IDs of the fragment IPatchworkAssignables
    @param target The address of the target IPatchworkLiteRef 
    @param targetTokenId The token ID of the target IPatchworkLiteRef 
    */
    function assignBatch(address[] calldata fragments, uint256[] calldata tokenIds, address target, uint256 targetTokenId) external payable;

    /**
    @notice Assign multiple fragments to a target in batch
    @param fragments The array of addresses of the fragment IPatchworkAssignables
    @param tokenIds The array of token IDs of the fragment IPatchworkAssignables
    @param target The address of the target IPatchworkLiteRef 
    @param targetTokenId The token ID of the target IPatchworkLiteRef 
    @param targetMetadataId The metadata ID on the target to store the references in
    */
    function assignBatch(address[] calldata fragments, uint256[] calldata tokenIds, address target, uint256 targetTokenId, uint256 targetMetadataId) external payable;

    /**
    @notice Unassign a fragment from a target
    @param fragment The IPatchworkSingleAssignable address of the fragment
    @param fragmentTokenId The IPatchworkSingleAssignable token ID of the fragment
    @dev reverts if fragment is not an IPatchworkSingleAssignable
    */
    function unassignSingle(address fragment, uint256 fragmentTokenId) external;
    
    /**
    @notice Unassign a fragment from a target
    @param fragment The IPatchworkSingleAssignable address of the fragment
    @param fragmentTokenId The IPatchworkSingleAssignable token ID of the fragment
    @param targetMetadataId The metadata ID on the target to unassign from
    @dev reverts if fragment is not an IPatchworkSingleAssignable
    */
    function unassignSingle(address fragment, uint256 fragmentTokenId, uint256 targetMetadataId) external;

    /**
    @notice Unassigns a multi relation
    @param fragment The IPatchworMultiAssignable address to unassign
    @param fragmentTokenId The IPatchworkMultiAssignable Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    @dev reverts if fragment is not an IPatchworkMultiAssignable
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) external;

    /**
    @notice Unassigns a multi relation
    @param fragment The IPatchworMultiAssignable address to unassign
    @param fragmentTokenId The IPatchworkMultiAssignable Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    @param targetMetadataId The metadata ID on the target to unassign from
    @dev reverts if fragment is not an IPatchworkMultiAssignable
    */
    function unassignMulti(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) external;

    /**
    @notice Unassigns a relation (single or multi)
    @param fragment The IPatchworkAssignable address to unassign
    @param fragmentTokenId The IPatchworkAssignable Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId) external;

    /**
    @notice Unassigns a relation (single or multi)
    @param fragment The IPatchworkAssignable address to unassign
    @param fragmentTokenId The IPatchworkAssignable Token ID to unassign
    @param target The IPatchworkLiteRef address which holds a reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID which holds a reference to the fragment
    @param targetMetadataId The metadata ID on the target to unassign from
    */
    function unassign(address fragment, uint256 fragmentTokenId, address target, uint256 targetTokenId, uint256 targetMetadataId) external;

    /**
    @notice Apply transfer rules and actions of a specific token from one address to another
    @param from The address of the sender
    @param to The address of the receiver
    @param tokenId The ID of the token to be transferred
    */
    function applyTransfer(address from, address to, uint256 tokenId) external;

    /**
    @notice Update the ownership tree of a specific Patchwork 721
    @param addr The address of the Patchwork 721
    @param tokenId The ID of the token whose ownership tree needs to be updated
    */
    function updateOwnershipTree(address addr, uint256 tokenId) external;

    /**
    @notice Propose an assigner delegate module
    @param addr The address of the new delegate module
    */
    function proposeAssignerDelegate(address addr) external;

    /**
    @notice Commit the proposed assigner delegate module
    @dev must be past timelock
    */
    function commitAssignerDelegate() external;
}