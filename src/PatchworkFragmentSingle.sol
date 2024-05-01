// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Patchwork721.sol";
import "./interfaces/IPatchworkSingleAssignable.sol";

/**
@title PatchworkFragmentSingle
@dev base implementation of a Single-relation Fragment is IPatchworkSingleAssignable
*/
abstract contract PatchworkFragmentSingle is Patchwork721, IPatchworkSingleAssignable {

    /// A mapping from token IDs in this contract to their assignments.
    mapping(uint256 => Assignment) internal _assignments;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkAssignable).interfaceId ||
        interfaceID == type(IPatchworkSingleAssignable).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

    /**
    @dev See {IPatchworkAssignableNFT-assign}
    */
    function assign(uint256 ourTokenId, address to, uint256 tokenId) public virtual mustHaveTokenWriteAuth(tokenId) {
        // One time use policy
        Assignment storage a = _assignments[ourTokenId];
        if (a.tokenAddr != address(0)) {
            revert IPatchworkProtocol.FragmentAlreadyAssigned(address(this), ourTokenId);
        }
        a.tokenAddr = to;
        a.tokenId = tokenId;
        emit Locked(ourTokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-unassign}
    */
    function unassign(uint256 tokenId) public virtual mustHaveTokenWriteAuth(tokenId) {
        if (_assignments[tokenId].tokenAddr == address(0)) {
            revert IPatchworkProtocol.FragmentNotAssigned(address(this), tokenId);
        }
        updateOwnership(tokenId);
        delete _assignments[tokenId];
        emit Unlocked(tokenId);
    }

    /**
    @dev See {IPatchworAssignable-allowAssignment}
    */
    function allowAssignment(uint256 ourTokenId, address /*target*/, uint256 /*targetTokenId*/, address targetOwner, address /*by*/, string memory /*scopeName*/) virtual public view returns (bool) {
        // By default only allow single assignments to be to the same owner as the target
        // Warning - Changing this without changing the other ownership logic in this contract to reflect this will make ownership inconsistent
        return targetOwner == ownerOf(ourTokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-updateOwnership}
    */
    function updateOwnership(uint256 tokenId) public virtual {
        Assignment storage assignment = _assignments[tokenId];
        if (assignment.tokenAddr != address(0)) {
            address owner_ = ownerOf(tokenId);
            address curOwner = super.ownerOf(tokenId);
            if (owner_ != curOwner) {
                // Parent ownership has changed, update our ownership to reflect this
                ERC721._transfer(curOwner, owner_, tokenId);
            }
        }
    }

    /**
    @dev owned by the assignment's owner
    @dev See {IERC721-ownerOf}
    */
    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        // If assigned, it's owned by the assignment, otherwise normal owner
        Assignment storage assignment = _assignments[tokenId];
        if (assignment.tokenAddr != address(0)) {
            return IERC721(assignment.tokenAddr).ownerOf(assignment.tokenId);
        }
        return super.ownerOf(tokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-unassignedOwnerOf}
    */
    function unassignedOwnerOf(uint256 tokenId) public virtual view returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
    @dev See {IPatchworkAssignableNFT-getAssignedTo}
    */
    function getAssignedTo(uint256 ourTokenId) public virtual view returns (address, uint256) {
         Assignment storage a = _assignments[ourTokenId];
         return (a.tokenAddr, a.tokenId); 
    }

    /**
    @dev See {IPatchworkAssignableNFT-onAssignedTransfer}
    */
    function onAssignedTransfer(address from, address to, uint256 tokenId) public virtual {
        require(msg.sender == _manager);
        emit Transfer(from, to, tokenId);
    }

    /**
    @dev See {IPatchwork721-locked}
    */
    function locked(uint256 tokenId) public view virtual override returns (bool) {
        // Locked when assigned (implicit) or if explicitly locked
        return _assignments[tokenId].tokenAddr != address(0) || super.locked(tokenId);
    }

    /**
    @dev See {IPatchwork721-setLocked}
    */
    function setLocked(uint256 tokenId, bool locked_) public virtual override {
        if (msg.sender != ownerOf(tokenId)) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        if (_assignments[tokenId].tokenAddr != address(0)) {
            revert AssignedFragmentCannotSetLocked(tokenId);
        }
        super.setLocked(tokenId, locked_);
    }
}