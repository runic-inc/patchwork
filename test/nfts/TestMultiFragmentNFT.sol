// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/PatchworkFragmentMulti.sol";
import "../../src/PatchworkLiteRef.sol";
import "../../src/interfaces/IPatchworkMintable.sol";

struct TestMultiFragmentNFTMetadata {
    uint8 nothing;
}

contract TestMultiFragmentNFT is PatchworkFragmentMulti, IPatchworkMintable {
    uint256 _nextTokenId;

    constructor (address _manager) Patchwork721("testscope", "TestMultiFragmentNFT", "TFLR", _manager, msg.sender) {
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return PatchworkFragmentMulti.supportsInterface(interfaceID) || 
            interfaceID == type(IPatchworkMintable).interfaceId;
    }

    function mint(address to, bytes calldata /* data */) public payable returns (uint256 tokenId) {
        if (msg.value > 0) {
            revert();
        }
        tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
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

    function setScopeName(string memory scopeName) public {
        // For testing only
        _scopeName = scopeName;
    }
    
    function schemaURI() pure external returns (string memory) {
        return "https://mything/my-fragment-metadata.json";
    }

    function imageURI(uint256 tokenId) pure external returns (string memory) {
        return string.concat("https://mything/my/", Strings.toString(tokenId), ".png");
    }
    
    /*
    Hard coded prototype schema is:
    slot 0 offset 0 = nothing
    */
    function schema() pure external returns (MetadataSchema memory) {
        MetadataSchemaEntry[] memory entries = new MetadataSchemaEntry[](8);
        entries[0] = MetadataSchemaEntry(0, 0, FieldType.UINT8, 1, FieldVisibility.PUBLIC, 0, 0, "nothing");
        return MetadataSchema(1, entries);
    }

    function packMetadata(TestMultiFragmentNFTMetadata memory data) public pure returns (uint256[] memory slots) {
        slots = new uint256[](1);
        slots[0] = uint256(data.nothing);
        return slots;
    }

    function storeMetadata(uint256 _tokenId, TestMultiFragmentNFTMetadata memory data) public {
        require(_checkTokenWriteAuth(_tokenId), "not authorized");
        _metadataStorage[_tokenId] = packMetadata(data);
    }

    function unpackMetadata(uint256[] memory slots) public pure returns (TestMultiFragmentNFTMetadata memory data) {
        data.nothing = uint8(slots[0]);
        return data;
    }

    function loadMetadata(uint256 _tokenId) public view returns (TestMultiFragmentNFTMetadata memory data) {
        return unpackMetadata(_metadataStorage[_tokenId]);
    }
}