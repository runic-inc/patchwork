// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../src/PatchworkAccountPatch.sol";

contract TestAccountPatchNFT is PatchworkAccountPatch {

    uint256 _nextTokenId = 0;
    bool _sameOwnerModel;

    struct TestPatchworkNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_, bool sameOwnerModel_) PatchworkNFT("testscope", "TestAccountPatchNFT", "TPLR", msg.sender, manager_) {
        _sameOwnerModel = sameOwnerModel_;
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

    function mintPatch(address to, address original) public returns (uint256) {
        if (msg.sender != _manager) {
            revert IPatchworkProtocol.NotAuthorized(msg.sender);
        }
        if (_sameOwnerModel) {
            if (to != original) {
                revert IPatchworkProtocol.MintNotAllowed(to);
            }
        }
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _storePatch(tokenId, original);
        _mint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
        return tokenId;
    }

    function burn(uint256 tokenId) public {
        // test only
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 /*batchSize*/
    ) internal override view{
        if (_sameOwnerModel) {
            // allow burn only
            if (from == address(0)) {
                // mint allowed
            } else if (to != address(0)) {
                revert IPatchworkProtocol.TransferNotAllowed(address(this), firstTokenId);
            }
       }
    }
}