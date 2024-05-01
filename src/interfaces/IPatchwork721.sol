// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC5192.sol";
import "./IPatchworkScoped.sol";

/** 
@title Patchwork Protocol Interface Metadata
@author Runic Labs, Inc
@notice Metadata for IPatchwork721 and related contract interfaces
*/
interface IPatchworkMetadata {
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
        CHAR8,    ///< An 8-character string (64 bits).
        CHAR16,   ///< A 16-character string (128 bits).
        CHAR32,   ///< A 32-character string (256 bits).
        CHAR64,   ///< A 64-character string (512 bits).
        LITEREF,  ///< A 64-bit Literef reference to a patchwork fragment.
        ADDRESS,  ///< A 160-bit address.
        STRING    ///< A dynamically-sized string.
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
        uint256 fieldCount;                ///< Number of elements of this field (0 = Dynamic Array, 1 = Single, >1 = Static Array)
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
@title Patchwork Protocol 721 Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork metadata standard
*/
interface IPatchwork721 is IPatchworkScoped, IPatchworkMetadata, IERC5192, IERC721 {
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
    @notice Emitted when the permissions are changed
    @param to The address the permissions are assigned to
    @param permissions The permissions
    */
    event PermissionChange(address indexed to, uint256 permissions);

    /**
    @notice Emitted when the schema has changed
    @param addr the address of the Patchwork721
    */
    event SchemaChange(address indexed addr);

    /**
    @notice Returns the URI of the schema
    @return string the URI of the schema
    */
    function schemaURI() external view returns (string memory);

    /**
    @notice Returns the metadata schema
    @return MetadataSchema the metadata schema
    */
    function schema() external view returns (MetadataSchema memory);

    /**
    @notice Returns the URI of the image associated with the given token ID
    @param tokenId ID of the token
    @return string the image URI
    */
    function imageURI(uint256 tokenId) external view returns (string memory);

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
    @notice Stores packed metadata for a given token ID
    @param tokenId ID of the token
    @param data Metadata to store
    */
    function storePackedMetadata(uint256 tokenId, uint256[] memory data) external;

    /**
    @notice Loads packed metadata for a given token ID and slot
    @param tokenId ID of the token
    @param slot Slot to load metadata from
    @return uint256 the raw slot data as a uint256
    */
    function loadPackedMetadataSlot(uint256 tokenId, uint256 slot) external view returns (uint256);

    /**
    @notice Loads packed metadata for a given token ID
    @param tokenId ID of the token
    @return uint256[] the raw slot data as a uint256 array
    */
    function loadPackedMetadata(uint256 tokenId) external view returns (uint256[] memory);

    /**
    @notice Returns the freeze nonce for a given token ID
    @param tokenId ID of the token
    @return nonce the nonce
    */
    function getFreezeNonce(uint256 tokenId) external view returns (uint256 nonce);

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