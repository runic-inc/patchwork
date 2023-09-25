// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./PatchworkNFTInterface.sol";
import "./PatchworkProtocol.sol";
import "./IERC4906.sol";

/**
@title PatchworkNFT Abstract Contract
@dev This abstract contract defines the core functionalities for the PatchworkNFT.
     It inherits from the standard ERC721, as well as the IPatchworkNFT and IERC4906 interfaces.
*/
abstract contract PatchworkNFT is ERC721, IPatchworkNFT, IERC4906 {

    /// @dev The scope name for the NFT.
    string internal _scopeName;

    /// @dev The address that denotes the owner of the contract.
    address internal _owner;

    /// @dev The address that manages the NFTs (PatchworkProtocol).
    address internal _manager;

    /// @dev A mapping to keep track of permissions for each address.
    mapping(address => uint256) internal _permissionsAllow;

    /// @dev A mapping for storing metadata associated with each NFT token ID.
    mapping(uint256 => uint256[]) internal _metadataStorage;

    /// @dev A mapping for storing freeze nonces of each NFT token ID.
    mapping(uint256 => uint256) internal _freezeNonces;

    /// @dev A mapping indicating whether a specific NFT token ID is frozen.
    mapping(uint256 => bool) internal _freezes;

    /// @dev A mapping indicating whether a specific NFT token ID is locked.
    mapping(uint256 => bool) internal _locks;

    /**
     * @notice Creates a new instance of the PatchworkNFT contract with the provided parameters.
     * @param scopeName_ The scope name for the NFT.
     * @param name_ The ERC-721 name for the NFT.
     * @param symbol_ The ERC-721 symbol for the NFT.
     * @param owner_ The address that will be set as the owner.
     * @param manager_ The address that will be set as the manager (PatchworkProtocol).
     */
    constructor(
        string memory scopeName_,
        string memory name_,
        string memory symbol_,
        address owner_,
        address manager_
    ) ERC721(name_, symbol_) {
        _scopeName = scopeName_;
        _owner = owner_;
        _manager = manager_;
    }

    /**
    @dev See {IPatchworkNFT-getScopeName}
    */
    function getScopeName() public view virtual returns (string memory) {
        return _scopeName;
    }

    /**
    @dev See {IPatchworkNFT-storePackedMetadataSlot}
    */
    function storePackedMetadataSlot(uint256 tokenId, uint256 slot, uint256 data) public virtual {
        if (!_checkTokenWriteAuth(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _metadataStorage[tokenId][slot] = data;
    }

    /**
    @dev See {IPatchworkNFT-loadPackedMetadataSlot}
    */
    function loadPackedMetadataSlot(uint256 tokenId, uint256 slot) public virtual view returns (uint256) {
        return _metadataStorage[tokenId][slot];
    }

    // Does msg.sender have permission to write to our top level storage?
    function _checkWriteAuth() internal virtual view returns (bool allow) {
        return (msg.sender == _owner);
    }

    // Does msg.sender have permission to write to this token's data?
    function _checkTokenWriteAuth(uint256 /*tokenId*/) internal virtual view returns (bool allow) {
        return (msg.sender == _owner || msg.sender == _manager);
    }

    /**
    @dev See {IPatchworkNFT-setPermissions}
    */
    function setPermissions(address to, uint256 permissions) public virtual {
        if (!_checkWriteAuth()) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _permissionsAllow[to] = permissions;
        emit PermissionChange(to, permissions);
    }

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceID == type(IPatchworkNFT).interfaceId ||
            interfaceID == type(IERC5192).interfaceId ||
            interfaceID == type(IERC4906).interfaceId ||    
            ERC721.supportsInterface(interfaceID);
    }

    /**
    @dev See {IERC721-transferFrom}.
    */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        PatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /**
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        PatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721, IERC721) {
        PatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
    @notice transfers a token with a known freeze nonce
    @dev reverts if the token is not frozen or if the current freeze nonce does not match the provided nonce
    @dev See {IERC721-transferFrom}.
    */
    function transferFromWithFreezeNonce(address from, address to, uint256 tokenId, uint256 nonce) public {
        if (!frozen(tokenId)) {
            revert PatchworkProtocol.NotFrozen(address(this), tokenId);
        }
        if (getFreezeNonce(tokenId) != nonce) {
            revert PatchworkProtocol.IncorrectNonce(address(this), tokenId, nonce);
        }
        transferFrom(from, to, tokenId);
    }

    /**
    @notice transfers a token with a known freeze nonce
    @dev reverts if the token is not frozen or if the current freeze nonce does not match the provided nonce
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFromWithFreezeNonce(address from, address to, uint256 tokenId, uint256 nonce) public {
        if (!frozen(tokenId)) {
            revert PatchworkProtocol.NotFrozen(address(this), tokenId);
        }
        if (getFreezeNonce(tokenId) != nonce) {
            revert PatchworkProtocol.IncorrectNonce(address(this), tokenId, nonce);
        }
        safeTransferFrom(from, to, tokenId);
    }

    /**
    @notice transfers a token with a known freeze nonce
    @dev reverts if the token is not frozen or if the current freeze nonce does not match the provided nonce
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFromWithFreezeNonce(address from, address to, uint256 tokenId, bytes memory data, uint256 nonce) public {
        if (!frozen(tokenId)) {
            revert PatchworkProtocol.NotFrozen(address(this), tokenId);
        }
        if (getFreezeNonce(tokenId) != nonce) {
            revert PatchworkProtocol.IncorrectNonce(address(this), tokenId, nonce);
        }
        safeTransferFrom(from, to, tokenId, data);
    }

    function _toString8(uint64 raw) internal pure returns (string memory out) {
        bytes memory byteArray = abi.encodePacked(bytes8(raw));
        // optimized shortcut out for full string value and no checks required later
        if (byteArray[7] != 0) {
            return string(byteArray);
        }
        return _trimUp(byteArray);
    }

    function _toString16(uint128 raw) internal pure returns (string memory out) {
        bytes memory byteArray = abi.encodePacked(bytes16(raw));
        // optimized shortcut out for full string value and no checks required later
        if (byteArray[15] != 0) {
            return string(byteArray);
        }
        return _trimUp(byteArray);
    }

    function _toString32(uint256 raw) internal pure returns (string memory out) {
        bytes memory byteArray = abi.encodePacked(bytes32(raw));
        // optimized shortcut out for full string value and no checks required later
        if (byteArray[31] != 0) {
            return string(byteArray);
        }
        return _trimUp(byteArray);
    }

    function _trimUp(bytes memory byteArray) internal pure returns (string memory out) {
        // uses about 40 more gas per call to be DRY, consider inlining to save gas if contract isn't too big
        uint nullPos = 0;
        while (true) {
            if (byteArray[nullPos] == 0) {
                break;
            }
            nullPos++;
        }
        bytes memory trimmedByteArray = new bytes(nullPos);
        for (uint256 i = 0; i < nullPos; i++) {
            trimmedByteArray[i] = byteArray[i];
        }
        out = string(trimmedByteArray);
    }

    /**
    @dev See {IPatchworkNFT-getFreezeNonce}
    */
    function getFreezeNonce(uint256 tokenId) public view virtual returns (uint256 nonce) {
        return _freezeNonces[tokenId];
    }

    /**
    @dev See {IPatchworkNFT-setFrozen}
    */
    function setFrozen(uint256 tokenId, bool frozen_) public virtual {
        if (msg.sender != ownerOf(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        bool _frozen = _freezes[tokenId];
        if (_frozen != frozen_) {
            if (frozen_) {
                _freezes[tokenId] = true;
                emit Frozen(tokenId);
            } else {
                _freezeNonces[tokenId]++;
                _freezes[tokenId] = false;
                emit Thawed(tokenId);
            }
        }
    }

    /**
    @dev See {IPatchworkNFT-frozen}
    */
    function frozen(uint256 tokenId) public view virtual returns (bool) {
        return _freezes[tokenId];
    }

    /**
    @dev See {IPatchworkNFT-locked}
    */
    function locked(uint256 tokenId) public view virtual returns (bool) {
        return _locks[tokenId];
    }

    /**
    @dev See {IPatchworkNFT-setLocked}
    */
    function setLocked(uint256 tokenId, bool locked_) public virtual {
        if (msg.sender != ownerOf(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        bool _locked = _locks[tokenId];
        if (_locked != locked_) {
            _locks[tokenId] = locked_;
            if (locked_) {
                emit Locked(tokenId);
            } else {
                emit Unlocked(tokenId);
            }
        }
    }
}

/**
@title PatchworkPatch
@dev Base implementation of IPatchworkPatch
@dev It is soul-bound to another ERC-721 and cannot be transferred or reassigned.
@dev It extends the functionalities of PatchworkNFT and implements the IPatchworkPatch interface.
*/
abstract contract PatchworkPatch is PatchworkNFT, IPatchworkPatch {

    /// @dev Mapping from token ID to the address of the NFT that this patch is applied to.
    mapping(uint256 => address) internal _patchedAddresses;

    /// @dev Mapping from token ID to the token ID of the NFT that this patch is applied to.
    mapping(uint256 => uint256) internal _patchedTokenIds;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkPatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkNFT-getScopeName}
    */
    function getScopeName() public view virtual override(PatchworkNFT, IPatchworkPatch) returns (string memory) {
        return _scopeName;
    }

    /**
    @dev will return the current owner of the patched address+tokenId
    @dev See {IERC721-ownerOf}
    */
    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        return IERC721(_patchedAddresses[tokenId]).ownerOf(_patchedTokenIds[tokenId]);
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalNFTAddress the address of the original ERC-721 we are patching
    @param originalNFTTokenId the tokenId of the original ERC-721 we are patching
    */
    function _storePatch(uint256 tokenId, address originalNFTAddress, uint256 originalNFTTokenId) internal virtual {
        _patchedAddresses[tokenId] = originalNFTAddress;
        _patchedTokenIds[tokenId] = originalNFTTokenId;
    }

    /**
    @dev See {IPatchworkPatch-updateOwnership}
    */
    function updateOwnership(uint256 tokenId) public virtual {
        address patchedAddr = _patchedAddresses[tokenId];
        if (patchedAddr != address(0)) {
            address owner_ = ownerOf(tokenId);
            address curOwner = super.ownerOf(tokenId);
            if (owner_ != curOwner) {
                // Parent ownership has changed, update our ownership to reflect this
                ERC721._transfer(curOwner, owner_, tokenId);
            }
        }
    }

    /**
    @dev See {IPatchworkPatch-unpatchedOwnerOf}
    */
    function unpatchedOwnerOf(uint256 tokenId) public virtual view returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
    @dev always false because a patch cannot be locked as the ownership is inferred
    @dev See {IPatchworkNFT-locked}
    */
    function locked(uint256 /* tokenId */) public pure virtual override returns (bool) {
        return false;
    }

    /**
    @dev always reverts because a patch cannot be locked as the ownership is inferred
    @dev See {IPatchworkNFT-setLocked}
    */ 
    function setLocked(uint256 /* tokenId */, bool /* locked_ */) public view virtual override {
        revert PatchworkProtocol.CannotLockSoulboundPatch(address(this));
    }

    /**
    @dev See {IPatchworkPatch-patchworkCompatible_}
    */ 
    function patchworkCompatible_() external pure returns (bytes1) {}
}

/**
@title PatchworkFragment
@dev base implementation of a Fragment is IPatchworkAssignableNFT
*/
abstract contract PatchworkFragment is PatchworkNFT, IPatchworkAssignableNFT {
 
    /// Represents an assignment of a token from an external NFT contract to a token in this contract.
    struct Assignment {
        address tokenAddr;  /// The address of the external NFT contract.
        uint256 tokenId;    /// The ID of the token in the external NFT contract.
    }

    /// A mapping from token IDs in this contract to their assignments.
    mapping(uint256 => Assignment) internal _assignments;

    /**
    @dev See {IPatchworkNFT-getScopeName}
    */
    function getScopeName() public view virtual override (IPatchworkAssignableNFT, PatchworkNFT) returns (string memory) {
        return _scopeName;
    }

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkAssignableNFT).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkAssignableNFT-assign}
    */
    function assign(uint256 ourTokenId, address to, uint256 tokenId) public virtual {
        if (!_checkTokenWriteAuth(ourTokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        // One time use policy
        Assignment storage a = _assignments[ourTokenId];
        if (a.tokenAddr != address(0)) {
            revert PatchworkProtocol.FragmentAlreadyAssigned(address(this), ourTokenId);
        }
        a.tokenAddr = to;
        a.tokenId = tokenId;
        emit Locked(ourTokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-unassign}
    */
    function unassign(uint256 tokenId) public virtual {
        if (!_checkTokenWriteAuth(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        updateOwnership(tokenId);
        delete _assignments[tokenId];
        emit Unlocked(tokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-updateOwnership}
    */
    function updateOwnership(uint256 tokenId) public virtual {
        Assignment storage assignment = _assignments[tokenId];
        if (assignment.tokenAddr != address(0)) {
            address owner_ = ownerOf(tokenId);
            address curOwner = super.ownerOf(tokenId);
            if (owner_ != curOwner) {
                // Parent ownership has changed, update our ownership to reflect this
                ERC721._transfer(curOwner, owner_, tokenId);
            }
        }
    }

    /**
    @dev owned by the assignment's owner
    @dev See {IERC721-ownerOf}
    */
    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        // If assigned, it's owned by the assignment, otherwise normal owner
        Assignment storage assignment = _assignments[tokenId];
        if (assignment.tokenAddr != address(0)) {
            return IERC721(assignment.tokenAddr).ownerOf(assignment.tokenId);
        }
        return super.ownerOf(tokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-unassignedOwnerOf}
    */
    function unassignedOwnerOf(uint256 tokenId) public virtual view returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-getAssignedTo}
    */
    function getAssignedTo(uint256 ourTokenId) public virtual view returns (address, uint256) {
         Assignment storage a = _assignments[ourTokenId];
         return (a.tokenAddr, a.tokenId); 
    }

    /**
    @dev See {IPatchworkAssignableNFT-onAssignedTransfer}
    */
    function onAssignedTransfer(address from, address to, uint256 tokenId) public virtual {
        require(msg.sender == _manager);
        emit Transfer(from, to, tokenId);
    }

    /**
    @dev See {IPatchworkNFT-locked}
    */
    function locked(uint256 tokenId) public view virtual override returns (bool) {
        // Locked when assigned (implicit) or if explicitly locked
        return _assignments[tokenId].tokenAddr != address(0) || super.locked(tokenId);
    }

    /**
    @dev See {IPatchworkNFT-setLocked}
    */
    function setLocked(uint256 tokenId, bool locked_) public virtual override {
        if (msg.sender != ownerOf(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        require(_assignments[tokenId].tokenAddr == address(0), "cannot setLocked assigned fragment");
        super.setLocked(tokenId, locked_);
    }

    /**
    @dev See {IPatchworkNFT-patchworkCompatible_}
    */
    function patchworkCompatible_() external pure returns (bytes2) {}
}

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
    function registerReferenceAddress(address addr) public virtual returns (uint8 id) {
        if (!_checkWriteAuth()) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        uint8 refId = _nextReferenceId;
        if (_nextReferenceId == 255) {
            revert PatchworkProtocol.OutOfIDs();
        }
        _nextReferenceId++;
        if (_referenceAddressIds[addr] != 0) {
            revert PatchworkProtocol.FragmentAlreadyRegistered(addr);
        }
        _referenceAddresses[refId] = addr;
        _referenceAddressIds[addr] = refId;
        return refId;
    }

    /**
    @dev See {IPatchworkLiteRef-redactReferenceAddress}
    */
    function redactReferenceAddress(uint8 id) public virtual {
        if (!_checkWriteAuth()) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _redactedReferenceIds[id] = true;
    }

    /**
    @dev See {IPatchworkLiteRef-unredactReferenceAddress}
    */
    function unredactReferenceAddress(uint8 id) public virtual {
        if (!_checkWriteAuth()) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _redactedReferenceIds[id] = false;
    }

    /**
    @dev See {IPatchworkLiteRef-getLiteReference}
    */
    function getLiteReference(address addr, uint256 tokenId) public virtual view returns (uint64 referenceAddress, bool redacted) {
        uint8 refId = _referenceAddressIds[addr];
        if (refId == 0) {
            return (0, false);
        }
        if (tokenId > 0xFFFFFFFFFFFFFF) {
            revert PatchworkProtocol.UnsupportedTokenId(tokenId);
        }
        return (uint64(uint256(refId) << 56 | tokenId), _redactedReferenceIds[refId]);
    }

    /**
    @dev See {IPatchworkLiteRef-getReferenceAddressAndTokenId}
    */
    function getReferenceAddressAndTokenId(uint64 referenceAddress) public virtual view returns (address addr, uint256 tokenId) {
        // <8 bits of refId, 56 bits of tokenId>
        uint8 refId = uint8(referenceAddress >> 56);
        tokenId = referenceAddress & 0x00FFFFFFFFFFFFFF; // 64 bit mask
        return (_referenceAddresses[refId], tokenId);
    }
}