// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/*
  Prototype - Generated Patchwork Meta contract for Totem NFT. 
  
  Is attached to any normal NFT and is scoped for a specific application. 

  Has metadata as defined in totem-metadata.json
*/

import "../PatchworkPatch.sol";
import "../PatchworkFragmentSingle.sol";

struct TestPatchFragmentNFTMetadata {
    uint16 xp;
    uint8 level;
    uint16 xpLost;
    uint16 stakedMade;
    uint16 stakedCorrect;
    uint8 evolution;
    string nickname;
}

contract TestPatchFragmentNFT is PatchworkPatch, PatchworkFragmentSingle {

    uint256 _nextTokenId;

    constructor(address manager_) PatchworkNFT("testscope", "TestPatchFragment", "TPLR", msg.sender, manager_) PatchworkFragmentSingle() {
    }

    // ERC-165
    function supportsInterface(bytes4 interfaceID) public view virtual override(PatchworkPatch, PatchworkFragmentSingle) returns (bool) {
        return PatchworkFragmentSingle.supportsInterface(interfaceID) ||
            PatchworkPatch.supportsInterface(interfaceID);        
    }

    function schemaURI() pure external override returns (string memory) {
        return "https://mything/my-metadata.json";
    }

    function imageURI(uint256 _tokenId) pure external override returns (string memory) {}

    function setManager(address manager_) external {
        require(_checkWriteAuth());
        _manager = manager_;
    }

    function getScopeName() public view virtual override(PatchworkPatch, PatchworkFragmentSingle) returns (string memory) {
        return _scopeName;
    }

    function setLocked(uint256 tokenId, bool locked_) public view virtual override(PatchworkPatch, PatchworkFragmentSingle) {
         return PatchworkPatch.setLocked(tokenId, locked_);
    }

    function locked(uint256 /* tokenId */) public pure virtual override(PatchworkPatch, PatchworkFragmentSingle) returns (bool) {
        return false;
    }

    function ownerOf(uint256 tokenId) public view virtual override(PatchworkPatch, PatchworkFragmentSingle) returns (address) {
        return PatchworkPatch.ownerOf(tokenId);
    }

    function updateOwnership(uint256 tokenId) public virtual override(PatchworkPatch, PatchworkFragmentSingle) {
        PatchworkPatch.updateOwnership(tokenId);
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
        entries[1] = MetadataSchemaEntry(1, 1, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 0, "xp");
        entries[2] = MetadataSchemaEntry(2, 2, FieldType.UINT8, 0, FieldVisibility.PUBLIC, 2, 16, "level");
        entries[3] = MetadataSchemaEntry(3, 0, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 24, "xpLost");
        entries[4] = MetadataSchemaEntry(4, 0, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 40, "stakedMade");
        entries[5] = MetadataSchemaEntry(5, 0, FieldType.UINT16, 0, FieldVisibility.PUBLIC, 2, 56, "stakedCorrect");
        entries[6] = MetadataSchemaEntry(6, 0, FieldType.UINT8, 0, FieldVisibility.PUBLIC, 2, 72, "evolution");
        entries[7] = MetadataSchemaEntry(7, 0, FieldType.CHAR16, 0, FieldVisibility.PUBLIC, 2, 80, "nickname");
        return MetadataSchema(1, entries);
    }

    function packMetadata(TestPatchFragmentNFTMetadata memory data) public pure returns (uint256[] memory slots) {
        bytes32 nickname;
        bytes memory ns = bytes(data.nickname);

        assembly {
            nickname := mload(add(ns, 32))
        }
        slots = new uint256[](1);
        slots[0] = uint256(data.xp) | uint256(data.level) << 16 | uint256(data.xpLost) << 24 | uint256(data.stakedMade) << 40 | uint256(data.stakedCorrect) << 56 | uint256(data.evolution) << 72 | uint256(nickname) >> 128 << 80;
        return slots;
    }

    function storeMetadata(uint256 _tokenId, TestPatchFragmentNFTMetadata memory data) public {
        require(_checkTokenWriteAuth(_tokenId), "not authorized");
        _metadataStorage[_tokenId] = packMetadata(data);
    }

    function unpackMetadata(uint256[] memory slots) public pure returns (TestPatchFragmentNFTMetadata memory data) {
        data.xp = uint16(slots[0]);
        data.level = uint8(slots[0] >> 16);
        data.xpLost = uint16(slots[0] >> 24);
        data.stakedMade = uint16(slots[0] >> 40);
        data.stakedCorrect = uint16(slots[0] >> 56);
        data.evolution = uint8(slots[0] >> 72);
        data.nickname = string(abi.encodePacked(bytes16(uint128(slots[0] >> 80))));
        return data;
    }

    function loadMetadata(uint256 _tokenId) public view returns (TestPatchFragmentNFTMetadata memory data) {
        return unpackMetadata(_metadataStorage[_tokenId]);
    }

    function mintPatch(address originalNFTOwner, address originalNFTAddress, uint originalNFTTokenId) external returns (uint256 tokenId){
        if (msg.sender != _manager) {
            revert();
        }
        // Just for testing
        tokenId = _nextTokenId;
        _nextTokenId++;
        _storePatch(tokenId, originalNFTAddress, originalNFTTokenId);
        _safeMint(originalNFTOwner, tokenId);
        _metadataStorage[tokenId] = new uint256[](3);
        return tokenId;
    }

    function burn(uint256 tokenId) public {
        // test only
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(PatchworkPatch, ERC721) {
        return PatchworkPatch._burn(tokenId);
    }
}