// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../src/Patchwork1155Patch.sol";

contract Test1155PatchNFT is Patchwork1155Patch {

    uint256 _nextTokenId = 0;
    bool _reverseEnabled = false;

    struct Test1155PatchNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_, bool reverseEnabled_) Patchwork721("testscope", "Test1155PatchNFT", "TPLR", msg.sender, manager_) {
        _reverseEnabled = reverseEnabled_;
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

    function mintPatch(address to, address originalNFTAddress, uint originalNFTTokenId, address account) external returns (uint256 tokenId){
        if (msg.sender != _manager) {
            revert();
        }
        // Just for testing
        tokenId = _nextTokenId;
        _nextTokenId++;
        _storePatch(tokenId, originalNFTAddress, originalNFTTokenId, account, _reverseEnabled);
        _safeMint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

}