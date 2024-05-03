// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/PatchworkPatch.sol";
import "../../src/PatchworkFragmentSingle.sol";

struct TestPatchFragmentNFTMetadata {
    uint16 xp;
    uint8 level;
    uint16 xpLost;
    uint16 stakedMade;
    uint16 stakedCorrect;
    uint8 evolution;
    string nickname;
}

contract TestPatchFragmentNFT is PatchworkReversiblePatch, PatchworkFragmentSingle {

    uint256 _nextTokenId;

    constructor(address manager_) Patchwork721("testscope", "TestPatchFragment", "TPLR", manager_, msg.sender) PatchworkFragmentSingle() {
    }

    // ERC-165
    function supportsInterface(bytes4 interfaceID) public view virtual override(PatchworkReversiblePatch, PatchworkFragmentSingle) returns (bool) {
        return PatchworkFragmentSingle.supportsInterface(interfaceID) ||
            PatchworkReversiblePatch.supportsInterface(interfaceID);        
    }

    function schemaURI() pure external override returns (string memory) {
        return "https://mything/my-metadata.json";
    }

    function imageURI(uint256 tokenId) pure external returns (string memory) {
        return string.concat("https://mything/my/", Strings.toString(tokenId), ".png");
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

    function updateOwnership(uint256 tokenId) public virtual override(IPatchworkPatch, PatchworkPatch, PatchworkFragmentSingle) {
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
        entries[1] = MetadataSchemaEntry(1, 1, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 2, 0, "xp");
        entries[2] = MetadataSchemaEntry(2, 2, FieldType.UINT8, 1, FieldVisibility.PUBLIC, 2, 16, "level");
        entries[3] = MetadataSchemaEntry(3, 0, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 2, 24, "xpLost");
        entries[4] = MetadataSchemaEntry(4, 0, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 2, 40, "stakedMade");
        entries[5] = MetadataSchemaEntry(5, 0, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 2, 56, "stakedCorrect");
        entries[6] = MetadataSchemaEntry(6, 0, FieldType.UINT8, 1, FieldVisibility.PUBLIC, 2, 72, "evolution");
        entries[7] = MetadataSchemaEntry(7, 0, FieldType.CHAR16, 1, FieldVisibility.PUBLIC, 2, 80, "nickname");
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

    function mintPatch(address originalNFTOwner, PatchTarget memory target) external payable mustBeManager returns (uint256 tokenId){
        if (msg.value > 0) {
            revert();
        }
        // Just for testing
        tokenId = _nextTokenId;
        _nextTokenId++;
        _storePatch(tokenId, target);
        _safeMint(originalNFTOwner, tokenId);
        _metadataStorage[tokenId] = new uint256[](3);
        return tokenId;
    }

    function burn(uint256 tokenId) public {
        // test only
        _burnPatch(tokenId);
    }
}