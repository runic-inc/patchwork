// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Patchwork721.sol";
import "./interfaces/IPatchworkMultiAssignable.sol";

/**
@title PatchworkFragmentMulti
@dev base implementation of a Multi-relation Fragment is IPatchworkAssignable
*/
abstract contract PatchworkFragmentMulti is Patchwork721, IPatchworkMultiAssignable {

    struct AssignmentStorage {
        mapping(bytes32 => uint256) index;
        Assignment[] assignments;
    }

    // Only presence-checking is available here

    /// A mapping from token IDs in this contract to their assignments.
    mapping(uint256 => AssignmentStorage) internal _assignmentStorage;

    /**
    @dev See {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IPatchworkAssignable).interfaceId ||
        interfaceID == type(IPatchworkMultiAssignable).interfaceId ||
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
    }

    /**
    @notice Unassigns a token
    @param ourTokenId ID of our token
    */
    function unassign(uint256 ourTokenId, address target, uint256 targetTokenId) public virtual mustHaveTokenWriteAuth(ourTokenId) {
        AssignmentStorage storage store = _assignmentStorage[ourTokenId];
        (bool present, uint256 index, bytes32 targetHash) = _assignmentIndexOf(store, target, targetTokenId);
        if (!present) {
            revert IPatchworkProtocol.FragmentNotAssigned(address(this), ourTokenId);
        }
        Assignment[] storage assignments = store.assignments;
        if (assignments.length > 1) {
            // move the last element of the array into this index
            Assignment storage a = assignments[assignments.length-1];
            assignments[index] = a;
            store.index[keccak256(abi.encodePacked(a.tokenAddr, a.tokenId))] = index;
        }
        // shorten the array by 1
        assignments.pop();
        // delete the index
        delete store.index[targetHash];
    }

    function isAssignedTo(uint256 ourTokenId, address target, uint256 targetTokenId) public view virtual returns (bool) {
        (bool present,,) = _assignmentIndexOf(_assignmentStorage[ourTokenId], target, targetTokenId);
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
    @dev See {IPatchwork721-getAssignmentCount}
    */
    function getAssignmentCount(uint256 tokenId) public view returns (uint256) {
        return _assignmentStorage[tokenId].assignments.length;
    }

    /**
    @dev See {IPatchwork721-getAssignments}
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
    @dev See {IPatchworAssignable-allowAssignment}
    */
    function allowAssignment(uint256 /*ourTokenId*/, address /*target*/, uint256 /*targetTokenId*/, address /*targetOwner*/, address /*by*/, string memory /*scopeName*/) pure virtual public returns (bool) {
        // By default allow multi assignments public
        return true;
    }
}