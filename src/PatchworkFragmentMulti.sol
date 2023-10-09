// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PatchworkNFT.sol";
import "./IPatchworkMultiAssignableNFT.sol";

/**
@title PatchworkFragmentMulti
@dev base implementation of a Single-relation Fragment is IPatchworkAssignableNFT
*/
abstract contract PatchworkFragmentMulti is PatchworkNFT, IPatchworkMultiAssignableNFT {

    struct AssignmentStorage {
        mapping(bytes32 => uint256) index;
        Assignment[] assignments;
    }

    /// Represents an assignment of a token from an external NFT contract to a token in this contract.
    struct Assignment {
        address tokenAddr;  /// The address of the external NFT contract.
        uint256 tokenId;    /// The ID of the token in the external NFT contract.
    }

    // Only presence-checking is available here

    /// A mapping from token IDs in this contract to their assignments.
    mapping(uint256 => AssignmentStorage) internal _assignmentStorage;

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
    function assign(uint256 ourTokenId, address to, uint256 tokenId) public virtual mustHaveTokenWriteAuth(ourTokenId) {
        // TODO add this to ourTokenId
        AssignmentStorage storage store = _assignmentStorage[ourTokenId];
        bytes32 targetHash = keccak256(abi.encodePacked(to, tokenId));
        if (store.index[targetHash] == 0) {
            // Either the first element or does not exist
            // TODO dupe
        }
        uint256 idx = store.assignments.length;
        store.assignments[idx] = Assignment(to, tokenId);
        store.index[targetHash] = idx;
    }

    /**
    @notice Unassigns a token
    @param ourTokenId ID of our token
    */
    function unassign(uint256 ourTokenId, address target, uint256 targetTokenId) public virtual mustHaveTokenWriteAuth(ourTokenId) {
    }

    function isAssignedTo(uint256 ourTokenId, address target, uint256 targetTokenId) public view virtual returns (bool) {
        return false;
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