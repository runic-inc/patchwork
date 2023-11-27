// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IPatchworkAccountPatch.sol";
import "./IPatchworkProtocol.sol";
import "./PatchworkNFT.sol";

/**
@title PatchworkAccountPatch
@dev Base implementation of IPatchworkAccountPatch
@dev It extends the functionalities of PatchworkNFT and implements the IPatchworkAccountPatch interface.
*/
abstract contract PatchworkAccountPatch is PatchworkNFT, IPatchworkAccountPatch {
    
    /// @dev Mapping from token ID to the address of the NFT that this patch is applied to.
    mapping(uint256 => address) internal _patchedAddresses;

    /// @dev Mapping of original address to token Ids for reverse lookups
    mapping(address => uint256) internal _patchedAddressesRev;

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
    function getScopeName() public view virtual override(PatchworkNFT, IPatchworkScoped) returns (string memory) {
        return _scopeName;
    }

    /**
    @notice stores a patch
    @param tokenId the tokenId of the patch
    @param originalAccountAddress the account we are patching
    @param withReverse store reverse lookup
    */
    function _storePatch(uint256 tokenId, address originalAccountAddress, bool withReverse) internal virtual {
        // PatchworkProtocol handles uniqueness assertion
        _patchedAddresses[tokenId] = originalAccountAddress;
        if (withReverse) {
            _patchedAddressesRev[originalAccountAddress] = tokenId;
        }
    }

    /**
    @dev See {IPatchworkAccountPatch-getTokenIdForOriginalAccount}
    */
    function getTokenIdForOriginalAccount(address originalAddress) public view virtual returns (uint256 tokenId) {
        return _patchedAddressesRev[originalAddress];
    }

    /**
    @dev See {ERC721-_burn}
    */ 
    function _burn(uint256 /*tokenId*/) internal virtual override {
        revert IPatchworkProtocol.UnsupportedOperation();
    }
    
}