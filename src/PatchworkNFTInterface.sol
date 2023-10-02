// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC5192.sol";

/** 
@title Patchwork Protocol NFT Interface Metadata
@author Runic Labs, Inc
@notice Metadata for IPatchworkNFT and related contract interfaces
*/
interface PatchworkNFTInterfaceMeta {
    /**
    @notice Enumeration of possible field data types.
    @dev This defines the various basic data types for the fields.
     */
    enum FieldType {
        BOOLEAN,  ///< A Boolean type (true or false).
        INT8,     ///< An 8-bit signed integer.
        INT16,    ///< A 16-bit signed integer.
        INT32,    ///< A 32-bit signed integer.
        INT64,    ///< A 64-bit signed integer.
        INT128,   ///< A 128-bit signed integer.
        INT256,   ///< A 256-bit signed integer.
        UINT8,    ///< An 8-bit unsigned integer.
        UINT16,   ///< A 16-bit unsigned integer.
        UINT32,   ///< A 32-bit unsigned integer.
        UINT64,   ///< A 64-bit unsigned integer.
        UINT128,  ///< A 128-bit unsigned integer.
        UINT256,  ///< A 256-bit unsigned integer.
        CHAR8,    ///< An 8-character string.
        CHAR16,   ///< A 16-character string.
        CHAR32,   ///< A 32-character string.
        CHAR64,   ///< A 64-character string.
        LITEREF  ///< A Literef reference to a patchwork fragment
    }

    /**
    @notice Struct defining the metadata schema.
    @dev This defines the overall structure of the metadata and contains entries describing each data field.
    */
    struct MetadataSchema {
        uint256 version;                    ///< Version of the metadata schema.
        MetadataSchemaEntry[] entries;      ///< Array of entries in the schema.
    }

    /**
    @notice Struct defining individual entries within the metadata schema.
    @dev Represents each data field in the schema, detailing its properties and type.
    */
    struct MetadataSchemaEntry {
        uint256 id;                        ///< Index or unique identifier of the entry.
        uint256 permissionId;              ///< Permission identifier associated with the entry.
        FieldType fieldType;               ///< Type of field data (from the FieldType enum).
        uint256 arrayLength;               ///< Length of array for the field (0 means it's a single field).
        FieldVisibility visibility;        ///< Visibility level of the field.
        uint256 slot;                      ///< Starting storage slot, may span multiple slots based on width.
        uint256 offset;                    ///< Offset in bits within the storage slot.
        string key;                        ///< Key or name associated with the field.
    }

    /**
    @notice Enumeration of field visibility options.
    @dev Specifies whether a field is publicly accessible or private.
    */
    enum FieldVisibility {
        PUBLIC,  ///< Field is publicly accessible.
        PRIVATE  ///< Field is private
    }
}

/**
@title Patchwork Protocol NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork metadata standard
*/
interface IPatchworkNFT is PatchworkNFTInterfaceMeta, IERC5192 {
    /**
    @notice Emitted when the freeze status is changed to frozen.
    @param tokenId The identifier for a token.
    */
    event Frozen(uint256 indexed tokenId);

    /**
    @notice Emitted when the locking status is changed to not frozen.
    @param tokenId The identifier for a token.
    */
    event Thawed(uint256 indexed tokenId);

    /**
    @notice Emitted when the permissions are changed for an NFT
    @param to The address the permissions are assigned to
    @param permissions The permissions
    */
    event PermissionChange(address indexed to, uint256 permissions);

    /**
    @notice Emitted when the schema has changed for an NFT
    @param addr the address of the NFT
    */
    event SchemaChange(address indexed addr);
    
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Returns the URI of the schema
    @return string the URI of the schema
    */
    function schemaURI() external returns (string memory);

    /**
    @notice Returns the metadata schema
    @return MetadataSchema the metadata schema
    */
    function schema() external returns (MetadataSchema memory);

    /**
    @notice Returns the URI of the image associated with the given token ID
    @param tokenId ID of the token
    @return string the image URI
    */
    function imageURI(uint256 tokenId) external returns (string memory);

    /**
    @notice Sets permissions for a given address
    @param to Address to set permissions for
    @param permissions Permissions value
    */
    function setPermissions(address to, uint256 permissions) external;

    /**
    @notice Stores packed metadata for a given token ID and slot
    @param tokenId ID of the token
    @param slot Slot to store metadata
    @param data Metadata to store
    */
    function storePackedMetadataSlot(uint256 tokenId, uint256 slot, uint256 data) external;

    /**
    @notice Loads packed metadata for a given token ID and slot
    @param tokenId ID of the token
    @param slot Slot to load metadata from
    @return uint256 the raw slot data as a uint256
    */
    function loadPackedMetadataSlot(uint256 tokenId, uint256 slot) external returns (uint256);

    /**
    @notice Returns the freeze nonce for a given token ID
    @param tokenId ID of the token
    @return nonce the nonce
    */
    function getFreezeNonce(uint256 tokenId) external returns (uint256 nonce);

    /**
    @notice Sets the freeze status of a token
    @param tokenId ID of the token
    @param frozen Freeze status to set
    */
    function setFrozen(uint256 tokenId, bool frozen) external;

    /**
    @notice Gets the freeze status of a token (ERC-5192)
    @param tokenId ID of the token
    @return bool true if frozen, false if not
     */
    function frozen(uint256 tokenId) external view returns (bool);

    /**
    @notice Sets the lock status of a token
    @param tokenId ID of the token
    @param locked Lock status to set
    */
    function setLocked(uint256 tokenId, bool locked) external;
}

/**
@title Patchwork Protocol Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchworkPatch {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Creates a new token for the owner, representing a patch
    @param owner Address of the owner of the token
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId ID of the original NFT token
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address owner, address originalNFTAddress, uint256 originalNFTTokenId) external returns (uint256 tokenId);

    /**
    @notice Updates the real underlying ownership of a token in storage (if different from current)
    @param tokenId ID of the token
    */
    function updateOwnership(uint256 tokenId) external;

    /**
    @notice Returns the underlying stored owner of a token ignoring real patched NFT ownership
    @param tokenId ID of the token
    @return address Address of the owner
    */
    function unpatchedOwnerOf(uint256 tokenId) external returns (address);

    /**
    @notice A deliberately incompatible function to block implementing both assignable and patch
    @return bytes1 Always returns 0x00
    */
    function patchworkCompatible_() external pure returns (bytes1);
}

/**
@title Patchwork Protocol Assignable NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork assignment
*/
interface IPatchworkAssignableNFT {
    /**
    @notice Get the scope this NFT claims to belong to
    @return string the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Assigns a token to another
    @param ourTokenId ID of our token
    @param to Address to assign to
    @param tokenId ID of the token to assign
    */
    function assign(uint256 ourTokenId, address to, uint256 tokenId) external;

    /**
    @notice Unassigns a token
    @param ourTokenId ID of our token
    */
    function unassign(uint256 ourTokenId) external;

    /**
    @notice Returns the address and token ID that our token is assigned to
    @param ourTokenId ID of our token
    @return address the address this is assigned to
    @return uint256 the tokenId this is assigned to
    */
    function getAssignedTo(uint256 ourTokenId) external view returns (address, uint256);

    /**
    @notice Returns the underlying stored owner of a token ignoring current assignment
    @param ourTokenId ID of our token
    @return address address of the owner
    */
    function unassignedOwnerOf(uint256 ourTokenId) external view returns (address);

    /**
    @notice Sends events for a token when the assigned-to token has been transferred
    @param from Sender address
    @param to Recipient address
    @param tokenId ID of the token
    */
    function onAssignedTransfer(address from, address to, uint256 tokenId) external;

    /**
    @notice Updates the real underlying ownership of a token in storage (if different from current)
    @param tokenId ID of the token
    */
    function updateOwnership(uint256 tokenId) external;

    /**
    @notice A deliberately incompatible function to block implementing both assignable and patch
    @return bytes2 Always returns 0x0000
    */
    function patchworkCompatible_() external pure returns (bytes2);
}

/**
@title Patchwork Protocol LiteRef NFT Interface
@author Runic Labs, Inc
@notice Interface for contracts that have Lite Reference ID support
*/
interface IPatchworkLiteRef {
    /**
    @notice Emitted when a contract redacts a fragment
    @param target the contract which issued the redaction
    @param fragment the fragment that was redacted
    */
    event Redact(address indexed target, address indexed fragment);

    /**
    @notice Emitted when a contract unredacts a fragment
    @param target the contract which revoked the redaction
    @param fragment the fragment that was unredacted
    */
    event Unredact(address indexed target, address indexed fragment);

    /**
    @notice Emitted when a contract registers a fragment
    @param target the contract that registered the fragment
    @param fragment the fragment that was registered
    @param idx the idx of the literef
    */
    event Register(address indexed target, address indexed fragment, uint8 idx);

    /**
    @notice Registers a reference address
    @param addr Address to register
    @return id ID assigned to the address
    */
    function registerReferenceAddress(address addr) external returns (uint8 id);

    /**
    @notice Redacts a reference address
    @param id ID of the address to redact
    */
    function redactReferenceAddress(uint8 id) external;

    /**
    @notice Unredacts a reference address
    @param id ID of the address to unredact
    */
    function unredactReferenceAddress(uint8 id) external;

    /**
    @notice Returns a lite reference for a given address and token ID
    @param addr Address to get reference for
    @param tokenId ID of the token
    @return liteRef Lite reference
    @return redacted Redacted status
    */
    function getLiteReference(address addr, uint256 tokenId) external view returns (uint64 liteRef, bool redacted);

    /**
    @notice Returns an address and token ID for a given lite reference
    @param liteRef Lite reference to get address and token ID for
    @return addr Address
    @return tokenId Token ID
    */
    function getReferenceAddressAndTokenId(uint64 liteRef) external view returns (address addr, uint256 tokenId);

    /**
    @notice Adds a reference to a token
    @param tokenId ID of the token
    @param referenceAddress Reference address to add
    */
    function addReference(uint256 tokenId, uint64 referenceAddress) external;

    /**
    @notice Adds multiple references to a token
    @param tokenId ID of the token
    @param liteRefs Array of lite references to add
    */
    function batchAddReferences(uint256 tokenId, uint64[] calldata liteRefs) external;

    /**
    @notice Removes a reference from a token
    @param tokenId ID of the token
    @param liteRef Lite reference to remove
    */
    function removeReference(uint256 tokenId, uint64 liteRef) external;

    /**
    @notice Loads a reference address and token ID at a given index
    @param idx Index to load from
    @return addr Address
    @return tokenId Token ID
    */
    function loadReferenceAddressAndTokenId(uint256 idx) external view returns (address addr, uint256 tokenId);

    /**
    @notice Loads all references for a given token ID
    @param tokenId ID of the token
    @return addresses Array of addresses
    @return tokenIds Array of token IDs
    */
    function loadAllReferences(uint256 tokenId) external view returns (address[] memory addresses, uint256[] memory tokenIds);
}
