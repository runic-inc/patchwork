// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./PatchworkNFTInterface.sol";

/** 
@title Patchwork Protocol
@author Runic Labs, Inc
@notice Manages data integrity of relational NFTs implemented with Patchwork interfaces 
*/
contract PatchworkProtocol {

    struct Scope {
        address owner;
        bool allowUserPatch;
        bool allowUserAssign;
        bool requireWhitelist;
        mapping(address => bool) operators;
        mapping(uint64 => bool) liteRefs;
        mapping(address => bool) whitelist;
        mapping(bytes32 => bool) uniquePatches;
    }

    mapping(string => Scope) _scopes;

    event Assign(address indexed owner, address fragmentAddress, uint256 fragmentTokenId, address indexed targetAddress, uint256 indexed targetTokenId);
    event Unassign(address indexed owner, address fragmentAddress, uint256 fragmentTokenId, address indexed targetAddress, uint256 indexed targetTokenId);
    event Patch(address indexed owner, address originalAddress, uint256 originalTokenId, address indexed patchAddress, uint256 indexed patchTokenId);

    /**
    @notice Claim a scope
    @param scopeName the name of the scope
    */
    function claimScope(string calldata scopeName) public {
        Scope storage s = _scopes[scopeName];
        require(s.owner == address(0), "scope already exists");
        s.owner = msg.sender;
    }

    /**
    @notice Transfer ownership of a scope
    @param scopeName Name of the scope
    @param newOwner Address of the new owner
    */
    function transferScopeOwnership(string calldata scopeName, address newOwner) public {
        Scope storage s = _scopes[scopeName];
        require(msg.sender == s.owner, "not authorized");
        require(newOwner != address(0), "not allowed");
        s.owner = newOwner;
    }

    /**
    @notice Get owner of a scope
    @param scopeName Name of the scope
    @return owner Address of the scope owner
    */
    function getScopeOwner(string calldata scopeName) public view returns (address owner) {
        return _scopes[scopeName].owner;
    }

    /**
    @notice Add an operator to a scope
    @param scopeName Name of the scope
    @param op Address of the operator
    */
    function addOperator(string calldata scopeName, address op) public {
        Scope storage s = _scopes[scopeName];
        require(msg.sender == s.owner, "not authorized");
        s.operators[op] = true;
    }

    /**
    @notice Remove an operator from a scope
    @param scopeName Name of the scope
    @param op Address of the operator
    */
    function removeOperator(string calldata scopeName, address op) public {
        Scope storage s = _scopes[scopeName];
        require(msg.sender == s.owner, "not authorized");
        s.operators[op] = false;
    }

    /**
    @notice Set rules for a scope
    @param scopeName Name of the scope
    @param allowUserPatch Boolean indicating whether user patches are allowed
    @param allowUserAssign Boolean indicating whether user assignments are allowed
    @param requireWhitelist Boolean indicating whether whitelist is required
    */
    function setScopeRules(string calldata scopeName, bool allowUserPatch, bool allowUserAssign, bool requireWhitelist) public {
        Scope storage s = _scopes[scopeName];
        require(msg.sender == s.owner, "not authorized");
        s.allowUserPatch = allowUserPatch;
        s.allowUserAssign = allowUserAssign;
        s.requireWhitelist = requireWhitelist;
    }

    /**
    @notice Add an address to a scope's whitelist
    @param scopeName Name of the scope
    @param addr Address to be whitelisted
    */
    function addWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _scopes[scopeName];
        require(msg.sender == s.owner || s.operators[msg.sender], "not authorized");
        s.whitelist[addr] = true;
    }

    /**
    @notice Remove an address from a scope's whitelist
    @param scopeName Name of the scope
    @param addr Address to be removed from the whitelist
    */
    function removeWhitelist(string calldata scopeName, address addr) public {
        Scope storage s = _scopes[scopeName];
        require(msg.sender == s.owner || s.operators[msg.sender], "not authorized");
        s.whitelist[addr] = false;
    }

    /**
    @notice Create a new patch
    @param originalNFTAddress Address of the original NFT
    @param originalNFTTokenId Token ID of the original NFT
    @param patchAddress Address of the IPatchworkPatch to mint
    @return tokenId Token ID of the newly created patch
    */
    function createPatch(address originalNFTAddress, uint originalNFTTokenId, address patchAddress) public returns (uint256 tokenId) {
        IPatchworkPatch patch = IPatchworkPatch(patchAddress);
        string memory scopeName = patch.getScopeName();
        // mint a Patch that is soulbound to the originalNFT using the contract address at patchAddress which must support Patchwork metadata
        Scope storage scope = _scopes[scopeName];
        if (scope.requireWhitelist) {
            require(scope.whitelist[patchAddress] == true, "not whitelisted in scope");
        }
        require(scope.owner != address(0), "scope does not exist");
        address tokenOwner = IERC721(originalNFTAddress).ownerOf(originalNFTTokenId);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserPatch && msg.sender == tokenOwner) {
            // continue
        } else {
            revert("not authorized");
        }
        // limit this to one unique patch (originalNFTAddress+TokenID+patchAddress)
        bytes32 _hash = keccak256(abi.encodePacked(originalNFTAddress, originalNFTTokenId, patchAddress));
        require(!scope.uniquePatches[_hash], "already patched");
        scope.uniquePatches[_hash] = true;
        tokenId = patch.mintPatch(tokenOwner, originalNFTAddress, originalNFTTokenId);
        emit Patch(tokenOwner, originalNFTAddress, originalNFTTokenId, patchAddress, tokenId);
        return tokenId;
    }

    /**
    @notice Assigns an NFT relation to have an IPatchworkLiteRef form a LiteRef to a IPatchworkAssignableNFT
    @param fragment The IPatchworkAssignableNFT address to assign
    @param fragmentTokenId The IPatchworkAssignableNFT Token ID to assign
    @param target The IPatchworkLiteRef address to hold the reference to the fragment
    @param targetTokenId The IPatchworkLiteRef Token ID to hold the reference to the fragment
    */
    function assignNFT(address fragment, uint fragmentTokenId, address target, uint targetTokenId) public {
        require(!_checkFrozen(fragment, fragmentTokenId), "frozen");
        require(!_checkFrozen(target, targetTokenId), "frozen");
        require(!(fragment == target && fragmentTokenId == targetTokenId), "self-assignment not allowed");
        IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(fragment);
        require(!_checkLocked(fragment, fragmentTokenId), "locked");
        // Use the fragment's scope for permissions, target already has to have fragment registered to be assignable
        string memory scopeName = assignableNFT.getScopeName();
        Scope storage scope = _scopes[scopeName];
        if (scope.requireWhitelist) {
            require(scope.whitelist[fragment] == true, "not whitelisted in scope");
        }
        require(scope.owner != address(0), "scope does not exist");
        address targetOwner = IERC721(target).ownerOf(targetTokenId);
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // Fragment and target must be same owner
            require(IERC721(fragment).ownerOf(fragmentTokenId) == targetOwner, "not authorized");   
        } else if (scope.allowUserAssign) {
            // If allowUserAssign is set for this scope, the sender must own both fragment and target
            require(IERC721(fragment).ownerOf(fragmentTokenId) == msg.sender, "not authorized");
            require(targetOwner == msg.sender, "not authorized");   
            // continue
        } else {
            revert("not authorized");
        }
        IPatchworkLiteRef targetLiteRefInterface = IPatchworkLiteRef(target);
        uint64 ref = targetLiteRefInterface.getLiteReference(fragment, fragmentTokenId);
        require(ref != 0, "unregistered fragment");
        require(!scope.liteRefs[ref], "already assigned in this scope");
        // call assign on the fragment
        assignableNFT.assign(fragmentTokenId, target, targetTokenId);
        // call addReference on the target
        targetLiteRefInterface.addReference(targetTokenId, ref);
        // add to our storage of scope->target assignments
        scope.liteRefs[ref] = true;
        emit Assign(targetOwner, fragment, fragmentTokenId, target, targetTokenId);
    }

    /**
    @notice Unassign a NFT fragment from a target NFT
    @param fragment The IPatchworkAssignableNFT address of the fragment NFT
    @param fragmentTokenId The IPatchworkAssignableNFT token ID of the fragment NFT
    */
    function unassignNFT(address fragment, uint fragmentTokenId) public {
        require(!_checkFrozen(fragment, fragmentTokenId), "frozen");
        IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(fragment);
        string memory scopeName = assignableNFT.getScopeName();
        Scope storage scope = _scopes[scopeName];
        require(scope.owner != address(0), "scope does not exist");
        if (scope.owner == msg.sender || scope.operators[msg.sender]) {
            // continue
        } else if (scope.allowUserAssign) {
            // If allowUserAssign is set for this scope, the sender must own both fragment
            require(IERC721(fragment).ownerOf(fragmentTokenId) == msg.sender, "not authorized"); 
            // continue
        } else {
            revert("not authorized");
        }
        (address target, uint256 targetTokenId) = IPatchworkAssignableNFT(fragment).getAssignedTo(fragmentTokenId);
        require(target != address(0), "not assigned");
        assignableNFT.unassign(fragmentTokenId);
        uint64 ref = IPatchworkLiteRef(target).getLiteReference(fragment, fragmentTokenId);
        require(ref != 0, "unregistered fragment");
        require(scope.liteRefs[ref], "ref not found in scope");
        scope.liteRefs[ref] = false;
        IPatchworkLiteRef(target).removeReference(targetTokenId, ref);
        emit Unassign(IERC721(target).ownerOf(targetTokenId), fragment, fragmentTokenId, target, targetTokenId);
    }

    /**
    @notice Assign multiple NFT fragments to a target NFT in batch
    @param fragments The array of addresses of the fragment IPatchworkAssignableNFTs
    @param tokenIds The array of token IDs of the fragment IPatchworkAssignableNFTs
    @param target The address of the target IPatchworkLiteRef NFT
    @param targetTokenId The token ID of the target IPatchworkLiteRef NFT
    */
    function batchAssignNFT(address[] calldata fragments, uint[] calldata tokenIds, address target, uint targetTokenId) public {
        require(fragments.length == tokenIds.length, "attribute addresses and token Ids must be the same length");
        require(!_checkFrozen(target, targetTokenId), "frozen");
        IPatchworkLiteRef targetLiteRefInterface = IPatchworkLiteRef(target);
        uint64[] memory refs = new uint64[](fragments.length);
        for (uint i = 0; i < fragments.length; i++) {
            address fragment = fragments[i];
            uint256 fragmentTokenId = tokenIds[i];
            require(!_checkFrozen(fragment, fragmentTokenId), "frozen");
            require(!(fragment == target && fragmentTokenId == targetTokenId), "self-assignment not allowed");
            IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(fragment);
            require(!_checkLocked(fragment, fragmentTokenId), "locked");
            // Use the fragment's scope for permissions, target already has to have fragment registered to be assignable
            string memory scopeName = assignableNFT.getScopeName();
            Scope storage scope = _scopes[scopeName]; // 2100 gas first access, 100 for each additional
            require(scope.owner != address(0), "scope does not exist");
            if (scope.requireWhitelist) {
                require(scope.whitelist[fragment] == true, "not whitelisted in scope");
            }
            address targetOwner = IERC721(target).ownerOf(targetTokenId);
            if (scope.owner == msg.sender || scope.operators[msg.sender]) {
                // continue
            } else if (scope.allowUserAssign) {
                // If allowUserAssign is set for this scope, the sender must own both fragment and target
                require(IERC721(fragment).ownerOf(fragmentTokenId) == msg.sender, "not authorized");   
                require(targetOwner == msg.sender, "not authorized");   
                // continue
            } else {
                revert("not authorized");
            }
            uint64 ref = targetLiteRefInterface.getLiteReference(fragment, fragmentTokenId);
            require(ref != 0, "unregistered fragment");
            require(!scope.liteRefs[ref], "already assigned in this scope");
            refs[i] = ref;
            // call assign on the fragment
            assignableNFT.assign(fragmentTokenId, target, targetTokenId);
            // add to our storage of scope->target assignments
            scope.liteRefs[ref] = true;
            emit Assign(targetOwner, fragment, fragmentTokenId, target, targetTokenId);
        }
        targetLiteRefInterface.batchAddReferences(targetTokenId, refs);
    }
    
    /**
    @notice Apply transfer rules and actions of a specific token from one address to another
    @param from The address of the sender
    @param to The address of the receiver
    @param tokenId The ID of the token to be transferred
    */
    function applyTransfer(address from, address to, uint256 tokenId) public {
        address nft = msg.sender;
        if (IERC165(nft).supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE)) {
            IPatchworkAssignableNFT assignableNFT = IPatchworkAssignableNFT(nft);
            (address addr, uint256 _tokenId) = assignableNFT.getAssignedTo(tokenId);
            require(addr == address(0) && _tokenId == 0, "transfer blocked by assignment");
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKPATCH_INTERFACE)) {
            revert("soulbound transfer not allowed");
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKNFT_INTERFACE)) {
            require(!IPatchworkNFT(nft).locked(tokenId), "locked");
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKLITEREF_INTERFACE)) {
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i]);
                }
            }
        }
    }

    function _applyAssignedTransfer(address nft, address from, address to, uint256 tokenId) internal {
        IPatchworkAssignableNFT(nft).onAssignedTransfer(from, to, tokenId);
        if (IERC165(nft).supportsInterface(IPATCHWORKLITEREF_INTERFACE)) {
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    _applyAssignedTransfer(addresses[i], from, to, tokenIds[i]);
                }
            }
        }
    }

    function _checkFrozen(address nft, uint256 tokenId) internal view returns (bool frozen) {
        if (IERC165(nft).supportsInterface(IPATCHWORKNFT_INTERFACE)) {
            if (IPatchworkNFT(nft).frozen(tokenId)) {
                return true;
            }
            if (IERC165(nft).supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE)) {
                (address assignedAddr, uint256 assignedTokenId) = IPatchworkAssignableNFT(nft).getAssignedTo(tokenId);
                if (assignedAddr != address(0)) {
                    return _checkFrozen(assignedAddr, assignedTokenId);
                }
            }
        }
        return false;
    }

    function _checkLocked(address nft, uint256 tokenId) internal view returns (bool locked) {
        if (IERC165(nft).supportsInterface(IPATCHWORKNFT_INTERFACE)) {
            if (IPatchworkNFT(nft).locked(tokenId)) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice Update the ownership tree of a specific Patchwork NFT
    @param nft The address of the Patchwork NFT
    @param tokenId The ID of the token whose ownership tree needs to be updated
    */
    function updateOwnershipTree(address nft, uint256 tokenId) public {
        if (IERC165(nft).supportsInterface(IPATCHWORKLITEREF_INTERFACE)) {
            IPatchworkLiteRef liteRefNFT = IPatchworkLiteRef(nft);
            (address[] memory addresses, uint256[] memory tokenIds) = liteRefNFT.loadAllReferences(tokenId);
            for (uint i = 0; i < addresses.length; i++) {
                if (addresses[i] != address(0)) {
                    updateOwnershipTree(addresses[i], tokenIds[i]);
                }
            }
        }
        if (IERC165(nft).supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE)) {
            IPatchworkAssignableNFT(nft).updateOwnership(tokenId);
        } else if (IERC165(nft).supportsInterface(IPATCHWORKPATCH_INTERFACE)) {
            IPatchworkPatch(nft).updateOwnership(tokenId);
        }
    }
}