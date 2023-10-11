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
        interfaceID == type(IPatchworkMultiAssignableNFT).interfaceId ||
        super.supportsInterface(interfaceID); 
    }

        /**
    @dev See {IPatchworkAssignableNFT-assign}
    */
    function assign(uint256 ourTokenId, address to, uint256 tokenId) public virtual mustHaveTokenWriteAuth(ourTokenId) {
        AssignmentStorage storage store = _assignmentStorage[ourTokenId];
        (bool present,, bytes32 targetHash) = _assignmentIndexOf(store, to, tokenId);
        if (present) {
            revert IPatchworkProtocol.FragmentAlreadyAssigned(address(this), ourTokenId);
        }
        Assignment[] storage assignments = store.assignments;
        uint256 idx = assignments.length;
        assignments.push(Assignment(to, tokenId));
        store.index[targetHash] = idx;
        // TODO emit event?
    }

    /**
    @notice Unassigns a token
    @param ourTokenId ID of our token
    */
    function unassign(uint256 ourTokenId, address target, uint256 targetTokenId) public virtual mustHaveTokenWriteAuth(ourTokenId) {
        AssignmentStorage storage store = _assignmentStorage[ourTokenId];
        (bool present, uint256 index, bytes32 targetHash) = _assignmentIndexOf(store, target, targetTokenId);
        if (present) {
            Assignment[] storage assignments = store.assignments;
            if (assignments.length > 1) {
                // move the last element of the array into this index
                assignments[index] = assignments[assignments.length-1];
            }
            // shorten the array by 1
            assignments.pop();
            // delete the index
            delete store.index[targetHash];
        } else {
            revert IPatchworkProtocol.FragmentNotAssigned(address(this), ourTokenId);
        }
        // TODO emit event?
    }

    function isAssignedTo(uint256 ourTokenId, address target, uint256 targetTokenId) public view virtual returns (bool) {
        (bool present,, bytes32 targetHash) = _assignmentIndexOf(_assignmentStorage[ourTokenId], target, targetTokenId);
        return present;
    }
    
    function _assignmentIndexOf(AssignmentStorage storage store, address target, uint256 targetTokenId) internal view returns (bool present, uint256 index, bytes32 targetHash) {
        targetHash = keccak256(abi.encodePacked(target, targetTokenId));
        uint256 storageIndex = store.index[targetHash];
        Assignment[] storage assignments = store.assignments;
        if (storageIndex == 0) {
            // Either the first element or does not exist
            if (assignments.length > 0) {
                // there is an assignment of some kind - need to check if it's this one
                if (assignments[0].tokenAddr == target && assignments[0].tokenId == targetTokenId) {
                    return (true, 0, targetHash);
                }
            }
        } else {
            // There is definitely an index to this.
            return (true, storageIndex, targetHash);
        }
        return (false, 0, targetHash);
    }


    /**
    @dev See {IPatchworkNFT-getAssignmentCount}
    */
    function getAssignmentCount(uint256 tokenId) public view returns (uint256) {
        return _assignmentStorage[tokenId].assignments.length;
    }

    /**
    @dev See {IPatchworkNFT-getAssignments}
    */
    function getAssignments(uint256 tokenId, uint256 offset, uint256 count) external view returns (Assignment[] memory) {
        AssignmentStorage storage store = _assignmentStorage[tokenId];
        Assignment[] storage assignments = store.assignments;
        if (offset >= assignments.length) {
            return new Assignment[](0);
        }
        // Determine the actual count of assignments to return
        uint256 retCount = count;
        if (offset + count > assignments.length) {
            retCount = assignments.length - offset;
        }
        // Fetch assignments
        Assignment[] memory page = new Assignment[](retCount);
        for (uint256 i = 0; i < retCount; i++) {
            page[i] = assignments[offset + i];
        }
        return page;
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