// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./interfaces/IPatchworkAccountPatch.sol";
import "./interfaces/IPatchworkProtocol.sol";
import "./Patchwork721.sol";

/**
@title PatchworkAccountPatch
@dev Base implementation of IPatchworkAccountPatch
@dev It extends the functionalities of Patchwork721 and implements the IPatchworkAccountPatch interface.
*/
abstract contract PatchworkAccountPatch is Patchwork721, IPatchworkAccountPatch {
    
    /// @dev Mapping from token ID to the address of the NFT that this patch is applied to.
    mapping(uint256 => address) internal _targetsById;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkAccountPatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param target the account we are patching
    */
    function _storePatch(uint256 tokenId, address target) internal virtual {
        // PatchworkProtocol handles uniqueness assertion
        _targetsById[tokenId] = target;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burnPatch(uint256 tokenId) internal virtual {
        address originalAddress = _targetsById[tokenId];
        IPatchworkProtocol(_manager).patchBurnedAccount(originalAddress, address(this));
        delete _targetsById[tokenId];
        super._burn(tokenId);
    }
    
}

/**
@title PatchworkReversibleAccountPatch
@dev PatchworkAccountPatch with reverse lookup function
*/
abstract contract PatchworkReversibleAccountPatch is PatchworkAccountPatch, IPatchworkReversibleAccountPatch {
    /// @dev Mapping of original address to token Ids for reverse lookups
    mapping(address => uint256) internal _idsByTarget;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkReversibleAccountPatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkAccountPatch-getTokenIdByTarget}
    */
    function getTokenIdByTarget(address target) public view virtual returns (uint256 tokenId) {
        return _idsByTarget[target];
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param target the account we are patching
    */
    function _storePatch(uint256 tokenId, address target) internal virtual override {
        // PatchworkProtocol handles uniqueness assertion
        _targetsById[tokenId] = target;
        _idsByTarget[target] = tokenId;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burnPatch(uint256 tokenId) internal virtual override {
        address target = _targetsById[tokenId];
        delete _idsByTarget[target];
        super._burnPatch(tokenId);
    }
}