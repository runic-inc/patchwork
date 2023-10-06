// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkAccountPatch.sol";
import "./PatchworkNFTBase.sol";
import "./PatchworkProtocol.sol";

/**
@title PatchworkAccountPatch
@dev Base implementation of IPatchworkAccountPatch
@dev It extends the functionalities of PatchworkNFT and implements the IPatchworkAccountPatch interface.
*/
abstract contract PatchworkAccountPatch is PatchworkNFT, IPatchworkAccountPatch {

    // TODO ownership models? Patched address is owner vs contract owner is owner vs assignable?
    
    /// @dev Mapping from token ID to the address of the NFT that this patch is applied to.
    mapping(uint256 => address) internal _patchedAddresses;
    /// @dev Mapping of address to track unique addresses patched
    mapping(address => bool) internal _uniqueAddresses;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkAccountPatch).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkNFT-getScopeName}
    */
    function getScopeName() public view virtual override(PatchworkNFT, IPatchworkAccountPatch) returns (string memory) {
        return _scopeName;
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalNFTAddress the account we are patching
    */
    function _storePatch(uint256 tokenId, address originalNFTAddress) internal virtual {
        if (_uniqueAddresses[originalNFTAddress]) {
            revert PatchworkProtocol.AddressAlreadyPatched(originalNFTAddress, address(this));
        }
        _uniqueAddresses[originalNFTAddress] = true;
        _patchedAddresses[tokenId] = originalNFTAddress;
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        address addr = _patchedAddresses[tokenId];
        delete _patchedAddresses[tokenId];
        delete _uniqueAddresses[addr];
    }

    /**
    @dev See {IPatchworkPatch-patchworkCompatible_}
    */ 
    function patchworkCompatible_() external pure returns (bytes3) {}
}