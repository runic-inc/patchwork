// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./PatchworkNFTInterface.sol";
import "./PatchworkProtocol.sol";
import "./IERC4906.sol";

abstract contract PatchworkNFT is ERC721, IPatchworkNFT, IERC4906 {
    string _scopeName;
    address _owner;
    address _manager;
    mapping(address => uint256) _permissionsAllow;
    mapping(uint256 => uint256[]) _metadataStorage;
    mapping(uint256 => uint256) _freezeNonces;
    mapping(uint256 => bool) _freezes;
    mapping(uint256 => bool) _locks;

    constructor(string memory scopeName_, string memory name_, string memory symbol_, address owner_, address manager_) ERC721(name_, symbol_) {
        _scopeName = scopeName_;
        _owner = owner_;
        _manager = manager_;
    }

    function getScopeName() public view virtual returns (string memory) {
        return _scopeName;
    }

    // Store 1 slot
    function storePackedMetadataSlot(uint256 tokenId, uint256 slot, uint256 data) public virtual {
        if (!_checkTokenWriteAuth(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _metadataStorage[tokenId][slot] = data;
    }

    // Load 1 slot
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

    function setPermissions(address to, uint256 permissions) public virtual {
        if (!_checkWriteAuth()) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _permissionsAllow[to] = permissions;
        emit PermissionChange(to, permissions);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceID == IPATCHWORKNFT_INTERFACE ||  //PatchworkNFTInterface id
            ERC721.supportsInterface(interfaceID) ||
            interfaceID == type(IERC5192).interfaceId ||
            interfaceID == type(IERC4906).interfaceId;        
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        PatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        PatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721, IERC721) {
        PatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFromWithFreezeNonce(address from, address to, uint256 tokenId, uint256 nonce) public {
        if (!frozen(tokenId)) {
            revert PatchworkProtocol.NotFrozen(address(this), tokenId);
        }
        if (getFreezeNonce(tokenId) != nonce) {
            revert PatchworkProtocol.IncorrectNonce(address(this), tokenId, nonce);
        }
        transferFrom(from, to, tokenId);
    }

    function safeTransferFromWithFreezeNonce(address from, address to, uint256 tokenId, uint256 nonce) public {
        if (!frozen(tokenId)) {
            revert PatchworkProtocol.NotFrozen(address(this), tokenId);
        }
        if (getFreezeNonce(tokenId) != nonce) {
            revert PatchworkProtocol.IncorrectNonce(address(this), tokenId, nonce);
        }
        safeTransferFrom(from, to, tokenId);
    }

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

    function getFreezeNonce(uint256 tokenId) public view virtual returns (uint256 nonce) {
        return _freezeNonces[tokenId];
    }

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

    function frozen(uint256 tokenId) public view virtual returns (bool) {
        return _freezes[tokenId];
    }

    /// @notice Returns the locking status
    /// @param tokenId The identifier for a token.
    function locked(uint256 tokenId) public view virtual returns (bool) {
        return _locks[tokenId];
    }

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

// A Patch is a soul-bound contract which patches an existing NFT. 
// It may not be transferred and may not be assignable.
abstract contract PatchworkPatch is PatchworkNFT, IPatchworkPatch {
    mapping(uint256 => address) _patchedAddresses;
    mapping(uint256 => uint256) _patchedTokenIds;

    function getScopeName() public view virtual override(PatchworkNFT, IPatchworkPatch) returns (string memory) {
        return _scopeName;
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        return IERC721(_patchedAddresses[tokenId]).ownerOf(_patchedTokenIds[tokenId]);
    }

    function _storePatch(uint256 tokenId, address originalNFTAddress, uint256 originalNFTTokenId) internal virtual {
        _patchedAddresses[tokenId] = originalNFTAddress;
        _patchedTokenIds[tokenId] = originalNFTTokenId;
    }

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

    function unpatchedOwnerOf(uint256 tokenId) public virtual view returns (address) {
        return super.ownerOf(tokenId);
    }

    function locked(uint256 /* tokenId */) public pure virtual override returns (bool) {
        return false;
    }

    function setLocked(uint256 /* tokenId */, bool /* locked_ */) public view virtual override {
        revert PatchworkProtocol.CannotLockSoulboundPatch(address(this));
    }

    function patchworkCompatible_() external pure returns (bytes1) {}
}

abstract contract PatchworkFragment is PatchworkNFT, IPatchworkAssignableNFT {
 
     struct Assignment {
        address tokenAddr;
        uint256 tokenId;
    }

    // token IDs to assignments
    mapping(uint256 => Assignment) _assignments;

    function getScopeName() public view virtual override (IPatchworkAssignableNFT, PatchworkNFT) returns (string memory) {
        return _scopeName;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == IPATCHWORKASSIGNABLENFT_INTERFACE || // PatchworkAssignableInterface id
        super.supportsInterface(interfaceID); 
    }

    function assign(uint256 ourTokenId, address to, uint256 tokenId) public virtual {
        // One time use policy
        if (!_checkTokenWriteAuth(ourTokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        Assignment storage a = _assignments[ourTokenId];
        if (a.tokenAddr != address(0)) {
            revert PatchworkProtocol.FragmentAlreadyAssigned(address(this), ourTokenId);
        }
        a.tokenAddr = to;
        a.tokenId = tokenId;
        emit Locked(ourTokenId);
    }

    function unassign(uint256 tokenId) public virtual {
        if (!_checkTokenWriteAuth(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        updateOwnership(tokenId);
        delete _assignments[tokenId];
        emit Unlocked(tokenId);
    }

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

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        // If assigned, it's owned by the assignment, otherwise normal owner
        Assignment storage assignment = _assignments[tokenId];
        if (assignment.tokenAddr != address(0)) {
            return IERC721(assignment.tokenAddr).ownerOf(assignment.tokenId);
        }
        return super.ownerOf(tokenId);
    }

    function unassignedOwnerOf(uint256 tokenId) public virtual view returns (address) {
        return super.ownerOf(tokenId);
    }

    function getAssignedTo(uint256 ourTokenId) public virtual view returns (address, uint256) {
         Assignment storage a = _assignments[ourTokenId];
         return (a.tokenAddr, a.tokenId); 
    }

    function onAssignedTransfer(address from, address to, uint256 tokenId) public virtual {
        require(msg.sender == _manager);
        emit Transfer(from, to, tokenId);
    }

    function locked(uint256 tokenId) public view virtual override returns (bool) {
        // Locked when assigned (implicit) or if explicitly locked
        return _assignments[tokenId].tokenAddr != address(0) || super.locked(tokenId);
    }

    function setLocked(uint256 tokenId, bool locked_) public virtual override {
        if (msg.sender != ownerOf(tokenId)) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        require(_assignments[tokenId].tokenAddr == address(0), "cannot setLocked assigned fragment");
        super.setLocked(tokenId, locked_);
    }

    function patchworkCompatible_() external pure returns (bytes2) {}
}

abstract contract PatchworkLiteRef is IPatchworkLiteRef, ERC165 {
    mapping(uint8 => address) _referenceAddresses;
    mapping(address => uint8) _referenceAddressIds;
    mapping(uint8 => bool) _redactedReferenceIds;
    uint8 _nextReferenceId;

    constructor() {
        _nextReferenceId = 1; // Start at 1 so we can identify if we already have one registered
    }

    function _checkWriteAuth() internal virtual returns (bool allow);

    // ERC-165
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == IPATCHWORKLITEREF_INTERFACE ||
            ERC165.supportsInterface(interfaceID);
    }

    // Register the artifact and other NFTs that we want assignable to this for composition or consumption
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

    function redactReferenceAddress(uint8 id) public virtual {
        if (!_checkWriteAuth()) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _redactedReferenceIds[id] = true;
    }

    function unredactReferenceAddress(uint8 id) public virtual {
        if (!_checkWriteAuth()) {
            revert PatchworkProtocol.NotAuthorized(msg.sender);
        }
        _redactedReferenceIds[id] = false;
    }

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

    function getReferenceAddressAndTokenId(uint64 referenceAddress) public virtual view returns (address addr, uint256 tokenId) {
        // <8 bits of refId, 56 bits of tokenId>
        uint8 refId = uint8(referenceAddress >> 56);
        tokenId = referenceAddress & 0x00FFFFFFFFFFFFFF; // 64 bit mask
        return (_referenceAddresses[refId], tokenId);
    }
}