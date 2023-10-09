// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PatchworkNFT.sol";
import "./IPatchworkMultiAssignableNFT.sol";

/**
@title PatchworkFragmentMulti
@dev base implementation of a Single-relation Fragment is IPatchworkAssignableNFT
*/
abstract contract PatchworkFragmentMulti is PatchworkNFT, IPatchworkMultiAssignableNFT {

    /**
    @dev See {IPatchworkNFT-getScopeName}
    */
    function getScopeName() public view virtual override (IPatchworkAssignableNFT, PatchworkNFT) returns (string memory) {
        return _scopeName;
    }

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkAssignableNFT).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

        /**
    @dev See {IPatchworkAssignableNFT-assign}
    */
    function assign(uint256 ourTokenId, address to, uint256 tokenId) public virtual mustHaveTokenWriteAuth(tokenId) {
        // TODO add this to ourTokenId
    }

    /**
    @dev See {IPatchworkAssignableNFT-unassign}
    */
    function unassign(uint256 tokenId) public virtual mustHaveTokenWriteAuth(tokenId) {
        // TODO remove this from ourTokenId
    }

    /**
    @dev See {IPatchworkAssignableNFT-getAssignedTo}
    */
    function getAssignedTo(uint256 ourTokenId) public virtual view returns (address, uint256) {
        // TODO this doesn't make sense for multi - need list to return but that could be super expensive
        // TODO we can have isAssignedTo that checks for ownership, but otherwise an indexer needs to handle this

        // Assignment storage a = _assignments[ourTokenId];
        //return (a.tokenAddr, a.tokenId); 
        return (address(0), 0);
    }

    /**
    @dev See {IPatchworkNFT-locked}
    */
    function locked(uint256 tokenId) public view virtual override returns (bool) {
        // TODO consider
        return super.locked(tokenId);
    }

    /**
    @dev See {IPatchworkNFT-setLocked}
    */
    function setLocked(uint256 tokenId, bool locked_) public virtual override {
        if (msg.sender != ownerOf(tokenId)) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        // TODO consider
        super.setLocked(tokenId, locked_);
    }

    /**
    @dev See {IPatchworkNFT-patchworkCompatible_}
    */
    function patchworkCompatible_() external pure returns (bytes2) {}
}