// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PatchworkNFT.sol";
import "./IPatchwork1155Patch.sol";

/**
@title Patchwork1155Patch
@dev Base implementation of IPatchwork1155Patch
@dev It extends the functionalities of PatchworkNFT and implements the IPatchwork1155Patch interface.
*/
abstract contract Patchwork1155Patch is PatchworkNFT, IPatchwork1155Patch {

    struct PatchCanonical {
        address addr;
        uint256 tokenId;
        address account;
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
    @dev See {IPatchworkNFT-getScopeName}
    */
    function getScopeName() public view virtual override(PatchworkNFT, IPatchwork1155Patch) returns (string memory) {
        return _scopeName;
    }

    /**
    @dev will return the 1155 bucket owner
    @dev See {IERC721-ownerOf}
    */
    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        return _patchedAddresses[tokenId].account;
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalNFTAddress the address of the original ERC-1155 we are patching
    @param originalNFTTokenId the tokenId of the original ERC-1155 we are patching
    @param account the account of the ERC-1155 we are patching
    */
    function _storePatch(uint256 tokenId, address originalNFTAddress, uint256 originalNFTTokenId, address account) internal virtual {
        _patchedAddresses[tokenId] = PatchCanonical(originalNFTAddress, originalNFTTokenId, account);
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 /*tokenId*/) internal virtual override {
        revert IPatchworkProtocol.UnsupportedOperation();
    }
}