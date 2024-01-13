// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Patchwork721.sol";
import "./interfaces/IPatchworkPatch.sol";

/**
@title PatchworkPatch
@dev Base implementation of IPatchworkPatch
@dev It is soul-bound to another ERC-721 and cannot be transferred or reassigned.
@dev It extends the functionalities of Patchwork721 and implements the IPatchworkPatch interface.
*/
abstract contract PatchworkPatch is Patchwork721, IPatchworkPatch {

    /// @dev A canonical path to an 721 patched
    struct PatchCanonical {
        address addr;    // The address of the 721
        uint256 tokenId; // The tokenId of the 721
    }

    /// @dev Mapping from token ID to the canonical address and tokenId of the NFT that this patch is applied to.
    mapping(uint256 => PatchCanonical) internal _patchedAddresses;

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
        PatchCanonical storage canonical = _patchedAddresses[tokenId];
        return IERC721(canonical.addr).ownerOf(canonical.tokenId);
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalAddress the address of the original ERC-721 we are patching
    @param originalTokenId the tokenId of the original ERC-721 we are patching
    */
    function _storePatch(uint256 tokenId, address originalAddress, uint256 originalTokenId) internal virtual {
        _patchedAddresses[tokenId] = PatchCanonical(originalAddress, originalTokenId);
    }

    /**
    @dev See {IPatchworkPatch-updateOwnership}
    */
    function updateOwnership(uint256 tokenId) public virtual {
        address patchedAddr = _patchedAddresses[tokenId].addr;
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
    function _burn(uint256 tokenId) internal virtual override {
        PatchCanonical storage canonical = _patchedAddresses[tokenId];
        IPatchworkProtocol(_manager).patchBurned(canonical.addr, canonical.tokenId, address(this));
        delete _patchedAddresses[tokenId];
        super._burn(tokenId);
    }
}

abstract contract PatchworkReversiblePatch is PatchworkPatch, IPatchworkReversiblePatch {
    /// @dev Mapping of hash of original address + token ID for reverse lookups
    mapping(bytes32 => uint256) internal _patchedAddressesRev; // hash of patched addr+tokenid to tokenId

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkReversiblePatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkPatch-getTokenIdForOriginal721}
    */
    function getTokenIdForOriginal721(address originalAddress, uint256 originalTokenId) public view virtual returns (uint256 tokenId) {
        return _patchedAddressesRev[keccak256(abi.encodePacked(originalAddress, originalTokenId))];
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalAddress the address of the original ERC-721 we are patching
    @param originalTokenId the tokenId of the original ERC-721 we are patching
    */
    function _storePatch(uint256 tokenId, address originalAddress, uint256 originalTokenId) internal virtual override {
        super._storePatch(tokenId, originalAddress, originalTokenId);
        _patchedAddressesRev[keccak256(abi.encodePacked(originalAddress, originalTokenId))] = tokenId;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 tokenId) internal virtual override {
        PatchCanonical storage canonical = _patchedAddresses[tokenId];
        delete _patchedAddressesRev[keccak256(abi.encodePacked(canonical.addr, canonical.tokenId))];
        super._burn(tokenId);
    }
}