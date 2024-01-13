// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Patchwork721.sol";
import "./interfaces/IPatchwork1155Patch.sol";

/**
@title Patchwork1155Patch
@dev Base implementation of IPatchwork1155Patch
@dev It extends the functionalities of Patchwork721 and implements the IPatchwork1155Patch interface.
*/
abstract contract Patchwork1155Patch is Patchwork721, IPatchwork1155Patch {

    /// @dev A canonical path to an 1155 patched
    struct PatchCanonical {
        address addr;    // The address of the 1155
        uint256 tokenId; // The tokenId of the 1155
        address account; // The account for the 1155
    }

    /// @dev Mapping from token ID to the canonical address of the NFT that this patch is applied to.
    mapping(uint256 => PatchCanonical) internal _patchedAddresses;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchwork1155Patch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalAddress the address of the original ERC-1155 we are patching
    @param originalTokenId the tokenId of the original ERC-1155 we are patching
    @param account the account of the ERC-1155 we are patching
    */
    function _storePatch(uint256 tokenId, address originalAddress, uint256 originalTokenId, address account) internal virtual {
        _patchedAddresses[tokenId] = PatchCanonical(originalAddress, originalTokenId, account);
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 tokenId) internal virtual override {
        PatchCanonical storage canonical = _patchedAddresses[tokenId];
        address originalAddress = canonical.addr;
        uint256 originalTokenId = canonical.tokenId;
        address account = canonical.account;
        IPatchworkProtocol(_manager).patchBurned1155(originalAddress, originalTokenId, account, address(this));
        delete _patchedAddresses[tokenId];
        super._burn(tokenId);
    }
}

/**
@title PatchworkReversible1155Patch
@dev Patchwork1155Patch with reverse lookup function
*/
abstract contract PatchworkReversible1155Patch is Patchwork1155Patch, IPatchworkReversible1155Patch {
    /// @dev Mapping of hash of original address + token ID + account for reverse lookups
    mapping(bytes32 => uint256) internal _patchedAddressesRev; // hash of patched addr+tokenid+account to tokenId

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkReversible1155Patch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchwork1155Patch-getTokenIdForOriginal1155}
    */
    function getTokenIdForOriginal1155(address originalAddress, uint256 originalTokenId, address originalAccount) public view virtual returns (uint256 tokenId) {
        return _patchedAddressesRev[keccak256(abi.encodePacked(originalAddress, originalTokenId, originalAccount))];
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalAddress the address of the original ERC-1155 we are patching
    @param originalTokenId the tokenId of the original ERC-1155 we are patching
    @param account the account of the ERC-1155 we are patching
    */
    function _storePatch(uint256 tokenId, address originalAddress, uint256 originalTokenId, address account) internal virtual override {
        _patchedAddresses[tokenId] = PatchCanonical(originalAddress, originalTokenId, account);
        _patchedAddressesRev[keccak256(abi.encodePacked(originalAddress, originalTokenId, account))] = tokenId;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 tokenId) internal virtual override {
        PatchCanonical storage canonical = _patchedAddresses[tokenId];
        address originalAddress = canonical.addr;
        uint256 originalTokenId = canonical.tokenId;
        address account = canonical.account;
        delete _patchedAddressesRev[keccak256(abi.encodePacked(originalAddress, originalTokenId, account))];
        super._burn(tokenId);
    }
}