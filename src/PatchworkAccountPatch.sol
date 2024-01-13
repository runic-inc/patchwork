// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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
    mapping(uint256 => address) internal _patchedAddresses;

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
    @param originalAccountAddress the account we are patching
    */
    function _storePatch(uint256 tokenId, address originalAccountAddress) internal virtual {
        // PatchworkProtocol handles uniqueness assertion
        _patchedAddresses[tokenId] = originalAccountAddress;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 tokenId) internal virtual override {
        address originalAddress = _patchedAddresses[tokenId];
        IPatchworkProtocol(_manager).patchBurnedAccount(originalAddress, address(this));
        delete _patchedAddresses[tokenId];
        super._burn(tokenId);
    }
    
}

/**
@title PatchworkReversibleAccountPatch
@dev PatchworkAccountPatch with reverse lookup function
*/
abstract contract PatchworkReversibleAccountPatch is PatchworkAccountPatch, IPatchworkReversibleAccountPatch {
    /// @dev Mapping of original address to token Ids for reverse lookups
    mapping(address => uint256) internal _patchedAddressesRev;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkReversibleAccountPatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkAccountPatch-getTokenIdForOriginalAccount}
    */
    function getTokenIdForOriginalAccount(address originalAddress) public view virtual returns (uint256 tokenId) {
        return _patchedAddressesRev[originalAddress];
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalAccountAddress the account we are patching
    */
    function _storePatch(uint256 tokenId, address originalAccountAddress) internal virtual override {
        // PatchworkProtocol handles uniqueness assertion
        _patchedAddresses[tokenId] = originalAccountAddress;
        _patchedAddressesRev[originalAccountAddress] = tokenId;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 tokenId) internal virtual override {
        address originalAddress = _patchedAddresses[tokenId];
        delete _patchedAddressesRev[originalAddress];
        super._burn(tokenId);
    }
}