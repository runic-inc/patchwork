// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../src/PatchworkNFT.sol";
import "../../src/IPatchworkMintable.sol";

contract TestPatchworkNFT is PatchworkNFT, IPatchworkMintable {

    uint256 _nextTokenId;

    struct TestPatchworkNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_) PatchworkNFT("testscope", "TestPatchworkNFT", "TPLR", msg.sender, manager_) {
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return PatchworkNFT.supportsInterface(interfaceID) || 
            interfaceID == type(IPatchworkMintable).interfaceId;
    }

    function schemaURI() pure external returns (string memory) {
        return "https://mything/my-nft-metadata.json";
    }

    function imageURI(uint256 _tokenId) pure external returns (string memory) {
        return string(abi.encodePacked("https://mything/nft-", _tokenId));
    }

    function schema() pure external returns (MetadataSchema memory) {
        MetadataSchemaEntry[] memory entries = new MetadataSchemaEntry[](1);
        entries[0] = MetadataSchemaEntry(1, 0, FieldType.UINT256, 1, FieldVisibility.PUBLIC, 2, 0, "thing");
        return MetadataSchema(1, entries);
    }

    function getScopeName() public view override (PatchworkNFT, IPatchworkMintable) returns (string memory scopeName) {
        return PatchworkNFT.getScopeName();
    }

    function mint(address to, bytes calldata /* data */) public returns (uint256 tokenId) {
        tokenId = _nextTokenId;
        _nextTokenId++;
        _mint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
    }
    
    function mintBatch(address to, bytes calldata data, uint256 quantity) external returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = mint(to, data);
        }
    }
}