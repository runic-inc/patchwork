// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/PatchworkPatch.sol";
import "../../src/PatchworkFragmentSingle.sol";

struct TestFragmentSingleNFTMetadata {
    uint16 xp;
    uint8 level;
    uint16 xpLost;
    uint16 stakedMade;
    uint16 stakedCorrect;
    uint8 evolution;
    string nickname;
}

contract TestFragmentSingleNFT is PatchworkFragmentSingle {

    uint256 _nextTokenId;

    constructor(address manager_) Patchwork721("testscope", "TestPatchFragment", "TPLR", manager_, msg.sender) PatchworkFragmentSingle() {
    }

    function schemaURI() pure external override returns (string memory) {
        return "https://mything/my-metadata.json";
    }

    function imageURI(uint256 tokenId) pure external returns (string memory) {
        return string.concat("https://mything/my/", Strings.toString(tokenId), ".png");
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

    function packMetadata(TestFragmentSingleNFTMetadata memory data) public pure returns (uint256[] memory slots) {
        bytes32 nickname;
        bytes memory ns = bytes(data.nickname);

        assembly {
            nickname := mload(add(ns, 32))
        }
        slots = new uint256[](1);
        slots[0] = uint256(data.xp) | uint256(data.level) << 16 | uint256(data.xpLost) << 24 | uint256(data.stakedMade) << 40 | uint256(data.stakedCorrect) << 56 | uint256(data.evolution) << 72 | uint256(nickname) >> 128 << 80;
        return slots;
    }

    function storeMetadata(uint256 _tokenId, TestFragmentSingleNFTMetadata memory data) public {
        require(_checkTokenWriteAuth(_tokenId), "not authorized");
        _metadataStorage[_tokenId] = packMetadata(data);
    }

    function unpackMetadata(uint256[] memory slots) public pure returns (TestFragmentSingleNFTMetadata memory data) {
        data.xp = uint16(slots[0]);
        data.level = uint8(slots[0] >> 16);
        data.xpLost = uint16(slots[0] >> 24);
        data.stakedMade = uint16(slots[0] >> 40);
        data.stakedCorrect = uint16(slots[0] >> 56);
        data.evolution = uint8(slots[0] >> 72);
        data.nickname = string(abi.encodePacked(bytes16(uint128(slots[0] >> 80))));
        return data;
    }

    function loadMetadata(uint256 _tokenId) public view returns (TestFragmentSingleNFTMetadata memory data) {
        return unpackMetadata(_metadataStorage[_tokenId]);
    }

    function mint(address to, bytes memory /*data*/) external returns (uint256 tokenId){
        // Just for testing
        tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
        return tokenId;
    }

    function burn(uint256 tokenId) public {
        // test only
        _burn(tokenId);
    }
}