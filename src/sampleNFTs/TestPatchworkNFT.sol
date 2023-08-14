// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../PatchworkNFTInterface.sol";
import "../PatchworkNFTBase.sol";

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

    // for _toString8
    function toString8(uint64 raw) public pure returns (string memory) {
        return _toString8(raw);
    }

    // for _toString16
    function toString16(uint128 raw) public pure returns (string memory) {
        return _toString16(raw);
    }

    // for _toString32
    function toString32(uint256 raw) public pure returns (string memory) {
        return _toString32(raw);
    }

}