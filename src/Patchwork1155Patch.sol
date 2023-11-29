// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Patchwork721.sol";
import "./IPatchwork1155Patch.sol";

/**
@title Patchwork1155Patch
@dev Base implementation of IPatchwork1155Patch
@dev It extends the functionalities of Patchwork721 and implements the IPatchwork1155Patch interface.
*/
abstract contract Patchwork1155Patch is Patchwork721, IPatchwork1155Patch {

    struct PatchCanonical {
        address addr;
        uint256 tokenId;
        address account;
    }

    /// @dev Mapping from token ID to the canonical address of the NFT that this patch is applied to.
    mapping(uint256 => PatchCanonical) internal _patchedAddresses;

    /// @dev Mapping of hash of original address + token ID + account for reverse lookups
    mapping(bytes32 => uint256) internal _patchedAddressesRev; // hash of patched addr+tokenid+account to tokenId

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchwork1155Patch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchwork721-getScopeName}
    */
    function getScopeName() public view virtual override(Patchwork721, IPatchworkScoped) returns (string memory) {
        return _scopeName;
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalNFTAddress the address of the original ERC-1155 we are patching
    @param originalNFTTokenId the tokenId of the original ERC-1155 we are patching
    @param withReverse store reverse lookup
    @param account the account of the ERC-1155 we are patching
    */
    function _storePatch(uint256 tokenId, address originalNFTAddress, uint256 originalNFTTokenId, address account, bool withReverse) internal virtual {
        _patchedAddresses[tokenId] = PatchCanonical(originalNFTAddress, originalNFTTokenId, account);
        if (withReverse) {
            _patchedAddressesRev[keccak256(abi.encodePacked(originalNFTAddress, originalNFTTokenId, account))] = tokenId;
        }
    }

    /**
    @dev See {IPatchwork1155Patch-getTokenIdForOriginalNFT}
    */
    function getTokenIdForOriginalNFT(address originalNFTAddress, uint256 originalNFTTokenId, address originalAccount) public view virtual returns (uint256 tokenId) {
        return _patchedAddressesRev[keccak256(abi.encodePacked(originalNFTAddress, originalNFTTokenId, originalAccount))];
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 /*tokenId*/) internal virtual override {
        revert IPatchworkProtocol.UnsupportedOperation();
    }
}