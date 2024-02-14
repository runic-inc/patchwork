// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/Patchwork721.sol";
import "../../src/interfaces/IPatchworkMintable.sol";

contract TestPatchworkNFT is Patchwork721, IPatchworkMintable {

    uint256 _nextTokenId;

    struct TestPatchworkNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_) Patchwork721("testscope", "TestPatchworkNFT", "TPLR", manager_, msg.sender) {
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return Patchwork721.supportsInterface(interfaceID) || 
            interfaceID == type(IPatchworkMintable).interfaceId;
    }

    function schemaURI() pure external returns (string memory) {
        return "https://mything/my-nft-metadata.json";
    }

    function imageURI(uint256 tokenId) pure external returns (string memory) {
        return string.concat("https://mything/my/", Strings.toString(tokenId), ".png");
    }

    function schema() pure external returns (MetadataSchema memory) {
        MetadataSchemaEntry[] memory entries = new MetadataSchemaEntry[](1);
        entries[0] = MetadataSchemaEntry(1, 0, FieldType.UINT256, 1, FieldVisibility.PUBLIC, 2, 0, "thing");
        return MetadataSchema(1, entries);
    }

    function getScopeName() public view override (Patchwork721, IPatchworkScoped) returns (string memory scopeName) {
        return Patchwork721.getScopeName();
    }

    function mint(address to, bytes calldata /* data */) public payable returns (uint256 tokenId) {
        if (msg.value > 0) {
            revert();
        }
        tokenId = _nextTokenId;
        _nextTokenId++;
        _mint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
    }
    
    function mintBatch(address to, bytes calldata data, uint256 quantity) public payable returns (uint256[] memory tokenIds) {
        if (msg.value > 0) {
            revert();
        }
        tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = mint(to, data);
        }
    }
}