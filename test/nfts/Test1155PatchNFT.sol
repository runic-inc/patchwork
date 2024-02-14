// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/Patchwork1155Patch.sol";

contract Test1155PatchNFT is Patchwork1155Patch {

    uint256 _nextTokenId = 0;

    struct Test1155PatchNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_) Patchwork721("testscope", "Test1155PatchNFT", "TPLR", manager_, msg.sender) {
    }

    function schemaURI() pure external returns (string memory) {
        return "https://mything/my-nft-metadata.json";
    }

    function imageURI(uint256 tokenId) pure external returns (string memory) {
        return string.concat("https://mything/my/", Strings.toString(tokenId), ".png");
    }

    function schema() pure external returns (MetadataSchema memory) {
        MetadataSchemaEntry[] memory entries = new MetadataSchemaEntry[](1);
        entries[0] = MetadataSchemaEntry(1, 0, FieldType.UINT256, 0, FieldVisibility.PUBLIC, 2, 0, "thing");
        return MetadataSchema(1, entries);
    }

    function mintPatch(address to, PatchTarget memory target) external payable mustBeManager returns (uint256 tokenId){
        if (msg.value > 0) {
            revert();
        }
        // Just for testing
        tokenId = _nextTokenId;
        _nextTokenId++;
        _storePatch(tokenId, target);
        _safeMint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        _burnPatch(tokenId);
    }

}

contract TestReversible1155PatchNFT is PatchworkReversible1155Patch {

    uint256 _nextTokenId = 0;

    struct TestReversible1155PatchNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_) Patchwork721("testscope", "Test1155PatchNFT", "TPLR", manager_, msg.sender) {
    }

    function schemaURI() pure external returns (string memory) {
        return "https://mything/my-nft-metadata.json";
    }

    function imageURI(uint256 _tokenId) pure external returns (string memory) {
        return string(abi.encodePacked("https://mything/nft-", _tokenId));
    }

    function schema() pure external returns (MetadataSchema memory) {
        MetadataSchemaEntry[] memory entries = new MetadataSchemaEntry[](1);
        entries[0] = MetadataSchemaEntry(1, 0, FieldType.UINT256, 0, FieldVisibility.PUBLIC, 2, 0, "thing");
        return MetadataSchema(1, entries);
    }

    function mintPatch(address to, PatchTarget memory target) external payable mustBeManager returns (uint256 tokenId){
        // Just for testing
        if (msg.value > 0) {
            revert();
        }
        tokenId = _nextTokenId;
        _nextTokenId++;
        _storePatch(tokenId, target);
        _safeMint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        _burnPatch(tokenId);
    }

}