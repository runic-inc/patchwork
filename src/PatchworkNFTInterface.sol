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

  enum FieldType {
    BOOLEAN,
    INT8,
    INT16,
    INT32,
    INT64,
    INT128,
    INT256,
    UINT8,
    UINT16,
    UINT32,
    UINT64,
    UINT128,
    UINT256,
    CHAR8,
    CHAR16,
    CHAR32,
    CHAR64,
    LITEREF
 }

  struct MetadataSchema {
    uint256 version;
    MetadataSchemaEntry[] entries;
  }

  struct MetadataSchemaEntry {
    uint256 id; // index
    uint256 permissionId;
    FieldType fieldType;
    uint256 arrayLength; // 0 is single field
    FieldVisibility visibility;
    uint256 slot; // start, may span more than one depending on width
    uint256 offset; // in bits
    string key;
  }

  enum FieldVisibility {
    PUBLIC,
    PRIVATE
  }
}

bytes4 constant IPATCHWORKNFT_INTERFACE = 0x017609f2;
bytes4 constant IPATCHWORKPATCH_INTERFACE = 0x4d721caf;
bytes4 constant IPATCHWORKASSIGNABLENFT_INTERFACE = 0x2c2b633b;
bytes4 constant IPATCHWORKLITEREF_INTERFACE = 0x0c790993;

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
    event Frozen(uint256 tokenId);

    /**
    @notice Emitted when the locking status is changed to not frozen.
    @param tokenId The identifier for a token.
    */
    event Thawed(uint256 tokenId);

    /**
    @notice Emitted when the permissions are changed for an NFT
    @param to The address the permissions are assigned to
    @param permissions The permissions
    */
    event PermissionChange(address indexed to, uint256 permissions);

    /**
    @notice Returns the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Returns the URI of the schema
    */
    function schemaURI() external returns (string memory);

    /**
    @notice Returns the metadata schema
    */
    function schema() external returns (MetadataSchema memory);

    /**
    @notice Returns the URI of the image associated with the given token ID
    @param _tokenId ID of the token
    */
    function imageURI(uint256 _tokenId) external returns (string memory);

    /**
    @notice Sets permissions for a given address
    @param to Address to set permissions for
    @param permissions Permissions value
    */
    function setPermissions(address to, uint256 permissions) external;

    /**
    @notice Stores packed metadata for a given token ID and slot
    @param _tokenId ID of the token
    @param slot Slot to store metadata
    @param data Metadata to store
    */
    function storePackedMetadataSlot(uint256 _tokenId, uint256 slot, uint256 data) external;

    /**
    @notice Loads packed metadata for a given token ID and slot
    @param _tokenId ID of the token
    @param slot Slot to load metadata from
    */
    function loadPackedMetadataSlot(uint256 _tokenId, uint256 slot) external returns (uint256);

    /**
    @notice Returns the freeze nonce for a given token ID
    @param tokenId ID of the token
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
    @return bool true if locked, false if not
     */
    function frozen(uint256 tokenId) external view returns (bool);

    /**
    @notice Sets the lock status of a token
    @param tokenId ID of the token
    @param locked Lock status to set
    */
    function setLocked(uint256 tokenId, bool locked) external;

    /**
    @notice Gets the lock status of a token (ERC-5192)
    @param tokenId ID of the token
    @return bool true if locked, false if not
     */
    function locked(uint256 tokenId) external view returns (bool);
}

/**
@title Patchwork Protocol Patch Interface
@author Runic Labs, Inc
@notice Interface for contracts supporting Patchwork patch standard
*/
interface IPatchworkPatch {
    /**
    @notice Returns the name of the scope
    */
    function getScopeName() external returns (string memory);

    /**
    @notice Creates a new token for the owner, representing a patch
    @param owner Address of the owner of the token
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId ID of the original NFT token
    @return tokenId ID of the newly minted token
    */
    function mintPatch(address owner, address originalNFTAddress, uint originalNFTTokenId) external returns (uint256 tokenId);

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
    @notice Returns the name of the scope
    */
    function getScopeName() external view returns (string memory);

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
    @return Address and token ID our token is assigned to
    */
    function getAssignedTo(uint256 ourTokenId) external view returns (address, uint256);

    /**
    @notice Returns the underlying stored owner of a token ignoring current assignment
    @param ourTokenId ID of our token
    @return Address of the owner
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
    */
    function getLiteReference(address addr, uint256 tokenId) external view returns (uint64 liteRef);

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


contract Selector {
    function calculatePatchworkNFTSelector() external pure returns (bytes4) {
        IPatchworkNFT i;
        return i.getScopeName.selector ^ i.schemaURI.selector ^ i.schema.selector ^ i.imageURI.selector ^ i.setPermissions.selector ^ 
            i.storePackedMetadataSlot.selector ^ i.loadPackedMetadataSlot.selector ^ i.getFreezeNonce.selector ^
            i.frozen.selector ^ i.setFrozen.selector ^ i.setLocked.selector;
    }
    function calculateERC165Selector() external pure returns (bytes4) {
        ERC165 i;
        return i.supportsInterface.selector;
    }
    function calculatePatchworkPatchSelector() external pure returns (bytes4) {
        IPatchworkPatch i;
        return i.getScopeName.selector ^ i.mintPatch.selector ^ i.updateOwnership.selector ^ i.unpatchedOwnerOf.selector ^
            i.patchworkCompatible_.selector;
    }
    function calculatePatchworkAssignableNFTSelector() external pure returns (bytes4) {
        IPatchworkAssignableNFT i;
        return i.getScopeName.selector ^ i.assign.selector ^ i.unassign.selector ^ i.getAssignedTo.selector ^ 
            i.unassignedOwnerOf.selector ^ i.onAssignedTransfer.selector ^ i.updateOwnership.selector ^ 
            i.patchworkCompatible_.selector;
    }
    function calculatePatchworkLightRefSelector() external pure returns (bytes4) {
        IPatchworkLiteRef i;
        return i.registerReferenceAddress.selector ^ i.redactReferenceAddress.selector ^ i.unredactReferenceAddress.selector ^ i.getLiteReference.selector ^ i.getReferenceAddressAndTokenId.selector ^ 
            i.addReference.selector ^ i.removeReference.selector ^ i.batchAddReferences.selector ^ i.loadReferenceAddressAndTokenId.selector ^ 
            i.loadAllReferences.selector;
    }
}