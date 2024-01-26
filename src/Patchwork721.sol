// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPatchwork721.sol";
import "./interfaces/IERC4906.sol";
import "./interfaces/IPatchworkProtocol.sol";

/**
@title Patchwork721 Abstract Contract
@dev This abstract contract defines the core functionalities for the Patchwork721.
     It inherits from the standard ERC721, as well as the IPatchwork721 and IERC4906 interfaces.
*/
abstract contract Patchwork721 is ERC721, IPatchwork721, IERC4906, Ownable {

    /// @dev The scope name of this 721.
    string internal _scopeName;

    /// @dev Our manager (PatchworkProtocol).
    address internal immutable _manager;

    /// @dev A mapping to keep track of permissions for each address.
    mapping(address => uint256) internal _permissionsAllow;

    /// @dev A mapping for storing metadata associated with each token ID.
    mapping(uint256 => uint256[]) internal _metadataStorage;

    /// @dev A mapping for storing freeze nonces of each token ID.
    mapping(uint256 => uint256) internal _freezeNonces;

    /// @dev A mapping indicating whether a specific token ID is frozen.
    mapping(uint256 => bool) internal _freezes;

    /// @dev A mapping indicating whether a specific token ID is locked.
    mapping(uint256 => bool) internal _locks;

    /**
    @notice Creates a new instance of the Patchwork721 contract with the provided parameters.
    @dev msg.sender will be initial owner
    @param scopeName_ The scope name.
    @param name_ The ERC-721 name.
    @param symbol_ The ERC-721 symbol.
    @param manager_ The address that will be set as the manager (PatchworkProtocol).
    @param owner_ The address that will be set as the owner
    */
    constructor(
        string memory scopeName_,
        string memory name_,
        string memory symbol_,
        address manager_,
        address owner_
    ) ERC721(name_, symbol_) Ownable(owner_) {
        _scopeName = scopeName_;
        _manager = manager_;
    } 

    /**
    @dev See {IPatchwork721-getScopeName}
    */
    function getScopeName() public view virtual returns (string memory) {
        return _scopeName;
    }

    /**
    @dev See {IPatchwork721-storePackedMetadataSlot}
    */
    function storePackedMetadataSlot(uint256 tokenId, uint256 slot, uint256 data) public virtual mustHaveTokenWriteAuth(tokenId) {
        _metadataStorage[tokenId][slot] = data;
    }

    /**
    @dev See {IPatchwork721-storePackedMetadata}
    */
    function storePackedMetadata(uint256 tokenId, uint256[] memory data) public virtual mustHaveTokenWriteAuth(tokenId) {
         _metadataStorage[tokenId] = data;
    }

    /**
    @dev See {IPatchwork721-loadPackedMetadataSlot}
    */
    function loadPackedMetadataSlot(uint256 tokenId, uint256 slot) public virtual view returns (uint256) {
        return _metadataStorage[tokenId][slot];
    }

    /**
    @dev See {IPatchwork721-loadPackedMetadata}
    */
    function loadPackedMetadata(uint256 tokenId) public virtual view returns (uint256[] memory) {
        return _metadataStorage[tokenId];
    }

    // Does msg.sender have permission to write to our top level storage?
    function _checkWriteAuth() internal virtual view returns (bool allow) {
        return (msg.sender == owner());
    }

    // Does msg.sender have permission to write to this token's data?
    function _checkTokenWriteAuth(uint256 /*tokenId*/) internal virtual view returns (bool allow) {
        return (msg.sender == owner() || msg.sender == _manager);
    }

    /**
    @dev See {IPatchwork721-setPermissions}
    */
    function setPermissions(address to, uint256 permissions) public virtual mustHaveWriteAuth {
        _permissionsAllow[to] = permissions;
        emit PermissionChange(to, permissions);
    }

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceID == type(IPatchwork721).interfaceId ||
            interfaceID == type(IERC5192).interfaceId ||
            interfaceID == type(IERC4906).interfaceId ||    
            interfaceID == type(IPatchworkScoped).interfaceId ||
            ERC721.supportsInterface(interfaceID);
    }

    /**
    @dev See {IERC721-transferFrom}.
    */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        IPatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /**
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721, IERC721) {
        IPatchworkProtocol(_manager).applyTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
    @notice transfers a token with a known freeze nonce
    @dev reverts if the token is not frozen or if the current freeze nonce does not match the provided nonce
    @dev See {IERC721-transferFrom}.
    */
    function transferFromWithFreezeNonce(address from, address to, uint256 tokenId, uint256 nonce) public mustBeFrozenWithNonce(tokenId, nonce) {
        transferFrom(from, to, tokenId);
    }

    /**
    @notice transfers a token with a known freeze nonce
    @dev reverts if the token is not frozen or if the current freeze nonce does not match the provided nonce
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFromWithFreezeNonce(address from, address to, uint256 tokenId, uint256 nonce) public mustBeFrozenWithNonce(tokenId, nonce) {
        safeTransferFrom(from, to, tokenId);
    }

    /**
    @notice transfers a token with a known freeze nonce
    @dev reverts if the token is not frozen or if the current freeze nonce does not match the provided nonce
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFromWithFreezeNonce(address from, address to, uint256 tokenId, bytes memory data, uint256 nonce) public mustBeFrozenWithNonce(tokenId, nonce) {
        safeTransferFrom(from, to, tokenId, data);
    }

    /**
    @dev See {IPatchwork721-getFreezeNonce}
    */
    function getFreezeNonce(uint256 tokenId) public view virtual returns (uint256 nonce) {
        return _freezeNonces[tokenId];
    }

    /**
    @dev See {IPatchwork721-setFrozen}
    */
    function setFrozen(uint256 tokenId, bool frozen_) public virtual mustBeTokenOwner(tokenId) {
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
    @dev See {IPatchwork721-frozen}
    */
    function frozen(uint256 tokenId) public view virtual returns (bool) {
        return _freezes[tokenId];
    }

    /**
    @dev See {IPatchwork721-locked}
    */
    function locked(uint256 tokenId) public view virtual returns (bool) {
        return _locks[tokenId];
    }

    /**
    @dev See {IPatchwork721-setLocked}
    */
    function setLocked(uint256 tokenId, bool locked_) public virtual mustBeTokenOwner(tokenId) {
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

    modifier mustHaveWriteAuth {
        if (!_checkWriteAuth()) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        _;
    }

    modifier mustHaveTokenWriteAuth(uint256 tokenId) {
        if (!_checkTokenWriteAuth(tokenId)) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        _;
    }
        
    modifier mustBeTokenOwner(uint256 tokenId) {
        if (msg.sender != ownerOf(tokenId)) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        _;
    }

    modifier mustBeFrozenWithNonce(uint256 tokenId, uint256 nonce) {
        if (!frozen(tokenId)) {
            revert IPatchworkProtocol.NotFrozen(address(this), tokenId);
        }
        if (getFreezeNonce(tokenId) != nonce) {
            revert IPatchworkProtocol.IncorrectNonce(address(this), tokenId, nonce);
        }
        _;
    }

    modifier mustBeManager() {
        if (msg.sender != _manager) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        _;
    }
}