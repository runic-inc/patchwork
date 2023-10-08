// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../PatchworkNFT.sol";

contract TestPatchworkNFT is PatchworkNFT {

    struct TestPatchworkNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_) PatchworkNFT("testscope", "TestPatchworkNFT", "TPLR", msg.sender, manager_) {
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

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
    }
}