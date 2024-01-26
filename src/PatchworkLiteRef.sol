// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IPatchworkLiteRef.sol";
import "./interfaces/IPatchworkProtocol.sol";

/**
@title PatchworkLiteRef
@dev base implementation of IPatchworkLiteRef
*/
abstract contract PatchworkLiteRef is IPatchworkLiteRef, ERC165 {
    
    /// A mapping from reference IDs to their associated addresses.
    mapping(uint8 => address) internal _referenceAddresses;
    
    /// A reverse mapping from addresses to their corresponding reference IDs.
    mapping(address => uint8) internal _referenceAddressIds;
    
    /// A mapping indicating which reference IDs have been redacted.
    mapping(uint8 => bool) internal _redactedReferenceIds;
    
    /// The ID that will be used for the next reference added.
    uint8 internal _nextReferenceId;

    /**
    @dev Constructor for the PatchworkLiteRef contract. Initializes the next reference ID to 1 to differentiate unregistered references.
    */
    constructor() {
        _nextReferenceId = 1; // Start at 1 so we can identify if we already have one registered
    }

    /**
    @notice implements a permission check for functions of this abstract class to use
    @return allow true if write is allowed, false if not
     */
    function _checkWriteAuth() internal virtual returns (bool allow);

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkLiteRef).interfaceId ||
            ERC165.supportsInterface(interfaceID);
    }

    /**
    @dev See {IPatchworkLiteRef-registerReferenceAddress}
    */
    function registerReferenceAddress(address addr) public virtual _mustHaveWriteAuth returns (uint8 id) {
        uint8 refId = _nextReferenceId;
        if (_nextReferenceId == 255) {
            revert IPatchworkProtocol.OutOfIDs();
        }
        _nextReferenceId++;
        if (_referenceAddressIds[addr] != 0) {
            revert IPatchworkProtocol.FragmentAlreadyRegistered(addr);
        }
        _referenceAddresses[refId] = addr;
        _referenceAddressIds[addr] = refId;
        emit Register(address(this), addr, refId);
        return refId;
    }

    /**
    @dev See {IPatchworkLiteRef-getReferenceId}
    */
    function getReferenceId(address addr) public virtual view returns (uint8 id, bool redacted) {
        uint8 refId = _referenceAddressIds[addr];
        return (refId, _redactedReferenceIds[refId]);
    }

    /**
    @dev See {IPatchworkLiteRef-getReferenceAddress}
    */
    function getReferenceAddress(uint8 id) public virtual view returns (address addr, bool redacted) {
        return (_referenceAddresses[id], _redactedReferenceIds[id]);
    }

    /**
    @dev See {IPatchworkLiteRef-redactReferenceAddress}
    */
    function redactReferenceAddress(uint8 id) public virtual _mustHaveWriteAuth {
        if (_referenceAddresses[id] == address(0)) {
            revert IPatchworkProtocol.FragmentUnregistered(address(0));
        }
        _redactedReferenceIds[id] = true;
        emit Redact(address(this), _referenceAddresses[id]);
    }

    /**
    @dev See {IPatchworkLiteRef-unredactReferenceAddress}
    */
    function unredactReferenceAddress(uint8 id) public virtual _mustHaveWriteAuth {
        if (_referenceAddresses[id] == address(0)) {
            revert IPatchworkProtocol.FragmentUnregistered(address(0));
        }
        _redactedReferenceIds[id] = false;
        emit Unredact(address(this), _referenceAddresses[id]);
    }

    /**
    @dev See {IPatchworkLiteRef-getLiteReference}
    */
    function getLiteReference(address addr, uint256 tokenId) public virtual view returns (uint64 liteRef, bool redacted) {
        uint8 refId = _referenceAddressIds[addr];
        if (refId == 0) {
            return (0, false);
        }
        if (tokenId > type(uint56).max) {
            revert IPatchworkProtocol.UnsupportedTokenId(tokenId);
        }
        return (uint64(uint256(refId) << 56 | tokenId), _redactedReferenceIds[refId]);
    }

    /**
    @dev See {IPatchworkLiteRef-getReferenceAddressAndTokenId}
    */
    function getReferenceAddressAndTokenId(uint64 liteRef) public virtual view returns (address addr, uint256 tokenId) {
        // <8 bits of refId, 56 bits of tokenId>
        uint8 refId = uint8(liteRef >> 56);
        tokenId = liteRef & 0x00FFFFFFFFFFFFFF; // 64 bit mask
        return (_referenceAddresses[refId], tokenId);
    }

    /**
    @dev See {IPatchworkLiteRef-loadAllStaticReferences}
    */
    function loadAllStaticReferences(uint256 tokenId) public virtual view returns (address[] memory addresses, uint256[] memory tokenIds) {}

    /**
    @dev See {IPatchworkLiteRef-getDynamicReferenceCount}
    */
    function getDynamicReferenceCount(uint256 tokenId) public virtual view returns (uint256 count) {}

    /**
    @dev See {IPatchworkLiteRef-loadDynamicReferencePage}
    */
    function loadDynamicReferencePage(uint256 tokenId, uint256 offset, uint256 count) public virtual view returns (address[] memory addresses, uint256[] memory tokenIds) {}

    modifier _mustHaveWriteAuth {
        if (!_checkWriteAuth()) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        _;
    }
}