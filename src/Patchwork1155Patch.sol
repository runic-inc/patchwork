// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Patchwork721.sol";
import "./interfaces/IPatchwork1155Patch.sol";

/**
@title Patchwork1155Patch
@dev Base implementation of IPatchwork1155Patch
@dev It extends the functionalities of Patchwork721 and implements the IPatchwork1155Patch interface.
*/
abstract contract Patchwork1155Patch is Patchwork721, IPatchwork1155Patch {

    /// @dev Mapping from token ID to the canonical address of the NFT that this patch is applied to.
    mapping(uint256 => PatchTarget) internal _targetsById;

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
    @param target the patch target
    */
    function _storePatch(uint256 tokenId, PatchTarget memory target) internal virtual {
        _targetsById[tokenId] = target;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burnPatch(uint256 tokenId) internal virtual {
        PatchTarget storage target = _targetsById[tokenId];
        address originalAddress = target.addr;
        uint256 originalTokenId = target.tokenId;
        address account = target.account;
        IPatchworkProtocol(_manager).patchBurned1155(originalAddress, originalTokenId, account, address(this));
        delete _targetsById[tokenId];
        _burn(tokenId);
    }
}

/**
@title PatchworkReversible1155Patch
@dev Patchwork1155Patch with reverse lookup function
*/
abstract contract PatchworkReversible1155Patch is Patchwork1155Patch, IPatchworkReversible1155Patch {
    /// @dev Mapping of hash of original address + token ID + account for reverse lookups
    mapping(bytes32 => uint256) internal _idsByTargetHash; // hash of patched addr+tokenid+account to tokenId

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkReversible1155Patch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchwork1155Patch-getTokenIdByTarget}
    */
    function getTokenIdByTarget(PatchTarget memory target) public view virtual returns (uint256 tokenId) {
        return _idsByTargetHash[keccak256(abi.encode(target))];
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param target the patch target
    */
    function _storePatch(uint256 tokenId, PatchTarget memory target) internal virtual override {
        _targetsById[tokenId] = target;
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