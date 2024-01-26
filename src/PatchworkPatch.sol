// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Patchwork721.sol";
import "./interfaces/IPatchworkPatch.sol";

/**
@title PatchworkPatch
@dev Base implementation of IPatchworkPatch
@dev It is soul-bound to another ERC-721 and cannot be transferred or reassigned.
@dev It extends the functionalities of Patchwork721 and implements the IPatchworkPatch interface.
*/
abstract contract PatchworkPatch is Patchwork721, IPatchworkPatch {

    /// @dev Mapping from token ID to the canonical address and tokenId of the NFT that this patch is applied to.
    mapping(uint256 => PatchTarget) internal _targetsById;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkPatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev will return the current owner of the patched address+tokenId
    @dev See {IERC721-ownerOf}
    */
    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        // Default is inherited ownership
        PatchTarget storage target = _targetsById[tokenId];
        return IERC721(target.addr).ownerOf(target.tokenId);
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param target the target 721 being patched
    */
    function _storePatch(uint256 tokenId, PatchTarget memory target) internal virtual {
        _targetsById[tokenId] = target;
    }

    /**
    @dev See {IPatchworkPatch-updateOwnership}
    */
    function updateOwnership(uint256 tokenId) public virtual {
        address patchedAddr = _targetsById[tokenId].addr;
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
    @dev See {IPatchworkPatch-ownerOfPatch}
    */
    function ownerOfPatch(uint256 tokenId) public virtual view returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    /**
    @dev always false because a patch cannot be locked as the ownership is inferred
    @dev See {IPatchwork721-locked}
    */
    function locked(uint256 /* tokenId */) public pure virtual override returns (bool) {
        return false;
    }

    /**
    @dev always reverts because a patch cannot be locked as the ownership is inferred
    @dev See {IPatchwork721-setLocked}
    */ 
    function setLocked(uint256 /* tokenId */, bool /* locked_ */) public view virtual override {
        revert IPatchworkProtocol.CannotLockSoulboundPatch(address(this));
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burnPatch(uint256 tokenId) internal virtual {
        PatchTarget storage target = _targetsById[tokenId];
        IPatchworkProtocol(_manager).patchBurned(target.addr, target.tokenId, address(this));
        delete _targetsById[tokenId];
        super._burn(tokenId);
    }
}

abstract contract PatchworkReversiblePatch is PatchworkPatch, IPatchworkReversiblePatch {
    /// @dev Mapping of hash of original address + token ID for reverse lookups
    mapping(bytes32 => uint256) internal _idsByTargetHash; // hash of patched addr+tokenid to tokenId

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkReversiblePatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkPatch-getTokenIdByTarget}
    */
    function getTokenIdByTarget(PatchTarget memory target) public view virtual returns (uint256 tokenId) {
        return _idsByTargetHash[keccak256(abi.encode(target))];
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param target the target 721 being patched
    */
    function _storePatch(uint256 tokenId, PatchTarget memory target) internal virtual override {
        super._storePatch(tokenId, target);
        _idsByTargetHash[keccak256(abi.encode(target))] = tokenId;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burnPatch(uint256 tokenId) internal virtual override {
        PatchTarget storage target = _targetsById[tokenId];
        delete _idsByTargetHash[keccak256(abi.encode(target))];
        super._burnPatch(tokenId);
    }
}