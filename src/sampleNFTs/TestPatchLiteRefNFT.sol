// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/*
  Prototype - Generated Patchwork Meta contract for Totem NFT. 
  
  Is attached to any normal NFT and is scoped for a specific application. 

  Has metadata as defined in totem-metadata.json
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "forge-std/console.sol";
import "../PatchworkNFTInterface.sol";
import "../PatchworkNFTBase.sol";


struct TestPatchLiteRefNFTMetadata {
    uint64[8] artifactIDs;
    uint16 xp;
    uint8 level;
    uint16 xpLost;
    uint16 stakedMade;
    uint16 stakedCorrect;
    uint8 evolution;
    string nickname;
}

contract TestPatchLiteRefNFT is PatchworkPatch, PatchworkLiteRef {

    uint256 _nextTokenId;

    constructor(address manager_) PatchworkNFT("testscope", "TestPatchLiteRef", "TPLR", msg.sender, manager_) PatchworkLiteRef() {
    }

    // ERC-165
    function supportsInterface(bytes4 interfaceID) public view virtual override(PatchworkNFT, PatchworkLiteRef) returns (bool) {
        return PatchworkLiteRef.supportsInterface(interfaceID) || 
            PatchworkNFT.supportsInterface(interfaceID) ||
            interfaceID == IPATCHWORKPATCH_INTERFACE;             
    }

    function schemaURI() pure external override returns (string memory) {
        return "https://mything/my-metadata.json";
    }

    function imageURI(uint256 _tokenId) pure external override returns (string memory) {}

    function setManager(address manager_) external {
        require(_checkWriteAuth());
        _manager = manager_;
    }

    /*
    Hard coded prototype schema is:
    slot 0 offset 0 = artifactIDs (spans 2) - also we need special built-in handling for < 256 bit IDs
    slot 2 offset 0 = xp
    slot 2 offset 16 = level
    slot 2 offset 24 = xpLost
    slot 2 offset 40 = stakedMade
    slot 2 offset 56 = stakedCorrect
    slot 2 offset 72 = evolution
    slot 2 offset 80 = nickname
    */
    function schema() pure external override returns (MetadataSchema memory) {
        MetadataSchemaEntry[] memory entries = new MetadataSchemaEntry[](8);
        entries[0] = MetadataSchemaEntry(0, 0, FieldType.UINT64, 8, FieldVisibility.PUBLIC, 0, 0, "artifactIDs");
        entries[1] = MetadataSchemaEntry(1, 1, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 0, "xp");
        entries[2] = MetadataSchemaEntry(2, 2, FieldType.UINT8, 0, FieldVisibility.PUBLIC, 2, 16, "level");
        entries[3] = MetadataSchemaEntry(3, 0, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 24, "xpLost");
        entries[4] = MetadataSchemaEntry(4, 0, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 40, "stakedMade");
        entries[5] = MetadataSchemaEntry(5, 0, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 56, "stakedCorrect");
        entries[6] = MetadataSchemaEntry(6, 0, FieldType.UINT8, 0, FieldVisibility.PUBLIC, 2, 72, "evolution");
        entries[7] = MetadataSchemaEntry(7, 0, FieldType.CHAR16, 0, FieldVisibility.PUBLIC, 2, 80, "nickname");
        return MetadataSchema(1, entries);
    }

    function packMetadata(TestPatchLiteRefNFTMetadata memory data) public pure returns (uint256[] memory slots) {
        bytes32 nickname;
        bytes memory ns = bytes(data.nickname);

        assembly {
            nickname := mload(add(ns, 32))
        }
        slots = new uint256[](3);
        slots[0] = uint256(data.artifactIDs[0]) | uint256(data.artifactIDs[1]) << 64 | uint256(data.artifactIDs[2]) << 128 | uint256(data.artifactIDs[3]) << 192;
        slots[1] = uint256(data.artifactIDs[4]) | uint256(data.artifactIDs[5]) << 64 | uint256(data.artifactIDs[6]) << 128 | uint256(data.artifactIDs[7]) << 192;
        slots[2] = uint256(data.xp) | uint256(data.level) << 16 | uint256(data.xpLost) << 24 | uint256(data.stakedMade) << 40 | uint256(data.stakedCorrect) << 56 | uint256(data.evolution) << 72 | uint256(nickname) >> 128 << 80;
        return slots;
    }

    function storeMetadata(uint256 _tokenId, TestPatchLiteRefNFTMetadata memory data) public {
        require(_checkTokenWriteAuth(_tokenId), "not authorized");
        _metadataStorage[_tokenId] = packMetadata(data);
    }

    function unpackMetadata(uint256[] memory slots) public pure returns (TestPatchLiteRefNFTMetadata memory data) {
        data.artifactIDs[0] = uint64(slots[0]);
        data.artifactIDs[1] = uint64(slots[0] >> 64);
        data.artifactIDs[2] = uint64(slots[0] >> 128);
        data.artifactIDs[3] = uint64(slots[0] >> 192);
        data.artifactIDs[4] = uint64(slots[1]);
        data.artifactIDs[5] = uint64(slots[1] >> 64);
        data.artifactIDs[6] = uint64(slots[1] >> 128);
        data.artifactIDs[7] = uint64(slots[1] >> 192);
        data.xp = uint16(slots[2]);
        data.level = uint8(slots[2] >> 16);
        data.xpLost = uint16(slots[2] >> 24);
        data.stakedMade = uint16(slots[2] >> 40);
        data.stakedCorrect = uint16(slots[2] >> 56);
        data.evolution = uint8(slots[2] >> 72);
        data.nickname = string(abi.encodePacked(bytes16(uint128(slots[2] >> 80))));
        return data;
    }

    function loadMetadata(uint256 _tokenId) public view returns (TestPatchLiteRefNFTMetadata memory data) {
        return unpackMetadata(_metadataStorage[_tokenId]);
    }

    // Store Only XP
    function storeXP(uint256 _tokenId, uint16 xp) public {
        require(_checkTokenWriteAuth(_tokenId) || _permissionsAllow[msg.sender] & 0x1 == 1, "not authorized");
        // Slot 2 offset 0: 16 bit value
        uint256 cleared = uint256(_metadataStorage[_tokenId][2]) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00;
        _metadataStorage[_tokenId][2] = cleared | uint256(xp);
    }

    // Load Only XP
    function loadXP(uint256 _tokenId) public view returns (uint16) {
        return uint16(uint256(_metadataStorage[_tokenId][2]));
    }

    // Store Only level
    function storeLevel(uint256 _tokenId, uint8 level) public {
        require(_checkTokenWriteAuth(_tokenId) || _permissionsAllow[msg.sender] & 0x2 == 1, "not authorized");
        // Slot 2 offset 16: 16 bit value
        uint256 cleared = uint256(_metadataStorage[_tokenId][2]) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FF;
        _metadataStorage[_tokenId][2] = cleared | (uint256(level) << 16);
    }

    // Load Only level
    function loadLevel(uint256 _tokenId) public view returns (uint16) {
        return uint16(uint256(_metadataStorage[_tokenId][2]) >> 16);
    }

    function addReference(uint256 ourTokenId, uint64 referenceAddress) public override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        uint256[] storage mdStorage = _metadataStorage[ourTokenId];
        uint256 slot = mdStorage[0];
        uint256 slot2 = mdStorage[1];
        if (uint64(slot) == 0) {
            mdStorage[0] = slot | referenceAddress;
        } else if (uint64(slot >> 64) == 0) {
            mdStorage[0] = slot | uint256(referenceAddress) << 64;
        } else if (uint64(slot >> 128) == 0) {
            mdStorage[0] = slot | uint256(referenceAddress) << 128;
        } else if (uint64(slot >> 192) == 0) {
            mdStorage[0] = slot | uint256(referenceAddress) << 192;
        } else if (uint64(slot2) == 0) {
            mdStorage[0] = slot2 | referenceAddress;
        } else if (uint64(slot2 >> 64) == 0) {
            mdStorage[0] = slot2 | uint256(referenceAddress) << 64;
        } else if (uint64(slot2 >> 128) == 0) {
            mdStorage[0] = slot2 | uint256(referenceAddress) << 128;
        } else if (uint64(slot2 >> 192) == 0) {
            mdStorage[0] = slot2 | uint256(referenceAddress) << 192;
        } else {
            revert("No reference slots available");
        }
    }

    function batchAddReferences(uint256 ourTokenId, uint64[] calldata /*_referenceAddresses*/) public view override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        // TODO bulk insert for fewer stores
    }

    function mintPatch(address originalNFTOwner, address originalNFTAddress, uint originalNFTTokenId) external returns (uint256 tokenId){
        // Just for testing
        tokenId = _nextTokenId;
        _nextTokenId++;
        _storePatch(tokenId, originalNFTAddress, originalNFTTokenId);
        _safeMint(originalNFTOwner, tokenId);
        _metadataStorage[tokenId] = new uint256[](3);
        return tokenId;
    }

    function removeReference(uint256 ourTokenId, uint64 referenceAddress) public override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        uint256[] storage mdStorage = _metadataStorage[ourTokenId];
        uint256 slot = mdStorage[0];
        uint256 slot2 = mdStorage[1];
        if (uint64(slot) == referenceAddress) {
            mdStorage[0] = slot & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000;
        } else if (uint64(slot >> 64) == referenceAddress) {
            mdStorage[0] = slot & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF;
        } else if (uint64(slot >> 128) == referenceAddress) {
            mdStorage[0] = slot & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else if (uint64(slot >> 192) == referenceAddress) {
            mdStorage[0] = slot & 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else if (uint64(slot2) == referenceAddress) {
            mdStorage[0] = slot2 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000;
        } else if (uint64(slot2 >> 64) == referenceAddress) {
            mdStorage[0] = slot2 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF;
        } else if (uint64(slot2 >> 128) == referenceAddress) {
            mdStorage[0] = slot2 & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else if (uint64(slot2 >> 192) == referenceAddress) {
            mdStorage[0] = slot2 & 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else {
            revert("not assigned");
        }
    }

    function loadReferenceAddressAndTokenId(uint256 idx) public view returns (address addr, uint256 tokenId) {
        uint256[] storage slots = _metadataStorage[tokenId];
        uint slotNumber = idx / 4;
        uint shift = (idx % 4) * 64; 
        uint64 attributeId = uint64(slots[slotNumber] >> shift);
        return getReferenceAddressAndTokenId(attributeId);
    }

    function loadAllReferences(uint256 tokenId) public view returns (address[] memory addresses, uint256[] memory tokenIds) {
        uint256[] storage slots = _metadataStorage[tokenId];
        addresses = new address[](8);
        tokenIds = new uint256[](8);
        for (uint i = 0; i < 8; i++) {
            uint slotNumber = i / 4; // integer division will get the correct slot number
            uint shift = (i % 4) * 64; // the remainder will give the correct shift
            uint64 attributeId = uint64(slots[slotNumber] >> shift);
            (address attributeAddress, uint256 attributeTokenId) = getReferenceAddressAndTokenId(attributeId);
            addresses[i] = attributeAddress;
            tokenIds[i] = attributeTokenId;
        }
        return (addresses, tokenIds);
    }
    
    function _checkWriteAuth() internal override(PatchworkNFT, PatchworkLiteRef) view returns (bool allow) {
        return PatchworkNFT._checkWriteAuth();
    }
}