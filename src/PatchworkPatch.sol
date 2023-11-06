// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PatchworkNFT.sol";
import "./IPatchworkPatch.sol";

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
        // Default is inherited ownership
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
        revert IPatchworkProtocol.CannotLockSoulboundPatch(address(this));
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 /*tokenId*/) internal virtual override {
        revert IPatchworkProtocol.UnsupportedOperation();
    }
}