// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/PatchworkAccountPatch.sol";

contract TestAccountPatchNFT is PatchworkReversibleAccountPatch {

    uint256 _nextTokenId = 0;
    bool _sameOwnerModel;

    struct TestPatchworkNFTMetadata {
        uint256 thing;
    }

    constructor(address manager_, bool sameOwnerModel_) Patchwork721("testscope", "TestAccountPatchNFT", "TPLR", manager_, msg.sender) {
        _sameOwnerModel = sameOwnerModel_;
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

    function mintPatch(address to, address original) public payable mustBeManager returns (uint256) {
        if (msg.value > 0) {
            revert();
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
        _burnPatch(tokenId);
    }

    /**
    @dev See {IERC721-transferFrom}.
    */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _checkTransfer(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /**
    @dev See {IERC721-safeTransferFrom}.
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        _checkTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _checkTransfer(address from, address to, uint256 tokenId) internal view {
            if (_sameOwnerModel) {
                // allow burn only
            if (from == address(0)) {
                // mint allowed
            } else if (to != address(0)) {
                revert IPatchworkProtocol.TransferNotAllowed(address(this), tokenId);
            }
       }
    }
}