// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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
    @notice Gets the ID assigned to the address from registration
    @param addr Registered address
    @return id ID assigned to the address
    @return redacted Redacted status
    */
    function getReferenceId(address addr) external view returns (uint8 id, bool redacted);

    /**
    @notice Gets the address assigned to this id
    @param id ID assigned to the address
    @return addr Registered address
    @return redacted Redacted status
    */
    function getReferenceAddress(uint8 id) external view returns (address addr, bool redacted);

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
    @param liteRef LiteRef to add
    */
    function addReference(uint256 tokenId, uint64 liteRef) external;

    /**
    @notice Adds a reference to a token
    @param tokenId ID of the token
    @param liteRef LiteRef to add
    @param targetMetadataId The metadata ID on the target to assign to
    */
    function addReference(uint256 tokenId, uint64 liteRef, uint256 targetMetadataId) external;

    /**
    @notice Adds multiple references to a token
    @param tokenId ID of the token
    @param liteRefs Array of lite references to add
    */
    function addReferenceBatch(uint256 tokenId, uint64[] calldata liteRefs) external;

    /**
    @notice Adds multiple references to a token
    @param tokenId ID of the token
    @param liteRefs Array of lite references to add
    @param targetMetadataId The metadata ID on the target to assign to
    */
    function addReferenceBatch(uint256 tokenId, uint64[] calldata liteRefs, uint256 targetMetadataId) external;

    /**
    @notice Removes a reference from a token
    @param tokenId ID of the token
    @param liteRef Lite reference to remove
    */
    function removeReference(uint256 tokenId, uint64 liteRef) external;

    /**
    @notice Removes a reference from a token
    @param tokenId ID of the token
    @param liteRef Lite reference to remove
    @param targetMetadataId The metadata ID on the target to unassign from
    */
    function removeReference(uint256 tokenId, uint64 liteRef, uint256 targetMetadataId) external;

    /**
    @notice Loads a reference address and token ID at a given index
    @param ourTokenId ID of the token
    @param idx Index to load from
    @return addr Address
    @return tokenId Token ID
    */
    function loadReferenceAddressAndTokenId(uint256 ourTokenId, uint256 idx) external view returns (address addr, uint256 tokenId);

    /**
    @notice Loads all static references for a given token ID
    @param tokenId ID of the token
    @return addresses Array of addresses
    @return tokenIds Array of token IDs
    */
    function loadAllStaticReferences(uint256 tokenId) external view returns (address[] memory addresses, uint256[] memory tokenIds);

    /**
    @notice Count all dynamic references for a given token ID
    @param tokenId ID of the token
    @return count the number of dynamic references
    */
    function getDynamicReferenceCount(uint256 tokenId) external view returns (uint256 count);

    /**
    @notice Load a page of dynamic references for a given token ID
    @param tokenId ID of the token
    @param offset The starting offset 0-indexed
    @param count The maximum number of references to return
    @return addresses An array of reference addresses
    @return tokenIds An array of reference token IDs
    */
    function loadDynamicReferencePage(uint256 tokenId, uint256 offset, uint256 count) external view returns (address[] memory addresses, uint256[] memory tokenIds);
}
