// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/Patchwork721.sol";
import "../../src/PatchworkLiteRef.sol";
import "../../src/interfaces/IPatchworkMintable.sol";
import "../../src/libraries/PatchworkDynamicRefs.sol";

struct TestDynamicArrayLiteRefNFTMetadata {
    uint16 xp;
    uint8 level;
    uint16 xpLost;
    uint16 stakedMade;
    uint16 stakedCorrect;
    uint8 evolution;
    string nickname;
}

contract TestDynamicRefLibraryNFT is Patchwork721, PatchworkLiteRef, IPatchworkMintable {

    uint256 _nextTokenId;

    mapping(uint256 => PatchworkDynamicRefs.DynamicLiteRefs) internal _dynamicLiterefStorage; // tokenId => indexed slots

    constructor(address manager_) Patchwork721("testscope", "TestPatchLiteRef", "TPLR", manager_, msg.sender) PatchworkLiteRef() {
    }

    // ERC-165
    function supportsInterface(bytes4 interfaceID) public view virtual override(Patchwork721, PatchworkLiteRef) returns (bool) {
        return Patchwork721.supportsInterface(interfaceID) ||
            PatchworkLiteRef.supportsInterface(interfaceID);
    }

    function schemaURI() pure external override returns (string memory) {
        return "https://mything/my-metadata.json";
    }

    function imageURI(uint256 tokenId) pure external returns (string memory) {
        return string.concat("https://mything/my/", Strings.toString(tokenId), ".png");
    }

    function mint(address to, bytes calldata /* data */) public payable returns (uint256 tokenId) {
        if (msg.value > 0) {
            revert();
        }
        tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](1);
        _dynamicLiterefStorage[tokenId].slots = new uint256[](0);
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
        entries[0] = MetadataSchemaEntry(0, 0, FieldType.LITEREF, 0, FieldVisibility.PUBLIC, 0, 0, "artifactIDs"); // Dynamic
        entries[1] = MetadataSchemaEntry(1, 1, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 0, 0, "xp");
        entries[2] = MetadataSchemaEntry(2, 2, FieldType.UINT8, 1, FieldVisibility.PUBLIC, 0, 16, "level");
        entries[3] = MetadataSchemaEntry(3, 0, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 0, 24, "xpLost");
        entries[4] = MetadataSchemaEntry(4, 0, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 0, 40, "stakedMade");
        entries[5] = MetadataSchemaEntry(5, 0, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 0, 56, "stakedCorrect");
        entries[6] = MetadataSchemaEntry(6, 0, FieldType.UINT8, 1, FieldVisibility.PUBLIC, 0, 72, "evolution");
        entries[7] = MetadataSchemaEntry(7, 0, FieldType.CHAR16, 1, FieldVisibility.PUBLIC, 0, 80, "nickname");
        return MetadataSchema(1, entries);
    }

    function packMetadata(TestDynamicArrayLiteRefNFTMetadata memory data) public pure returns (uint256[] memory slots) {
        bytes32 nickname;
        bytes memory ns = bytes(data.nickname);

        assembly {
            nickname := mload(add(ns, 32))
        }
        slots = new uint256[](1);
        slots[0] = uint256(data.xp) | uint256(data.level) << 16 | uint256(data.xpLost) << 24 | uint256(data.stakedMade) << 40 | uint256(data.stakedCorrect) << 56 | uint256(data.evolution) << 72 | uint256(nickname) >> 128 << 80;
        return slots;
    }

    function storeMetadata(uint256 _tokenId, TestDynamicArrayLiteRefNFTMetadata memory data) public {
        require(_checkTokenWriteAuth(_tokenId), "not authorized");
        _metadataStorage[_tokenId] = packMetadata(data);
    }

    function unpackMetadata(uint256[] memory slots) public pure returns (TestDynamicArrayLiteRefNFTMetadata memory data) {
        data.xp = uint16(slots[0]);
        data.level = uint8(slots[0] >> 16);
        data.xpLost = uint16(slots[0] >> 24);
        data.stakedMade = uint16(slots[0] >> 40);
        data.stakedCorrect = uint16(slots[0] >> 56);
        data.evolution = uint8(slots[0] >> 72);
        data.nickname = string(abi.encodePacked(bytes16(uint128(slots[0] >> 80))));
        return data;
    }

    function loadMetadata(uint256 _tokenId) public view returns (TestDynamicArrayLiteRefNFTMetadata memory data) {
        return unpackMetadata(_metadataStorage[_tokenId]);
    }

    // Store Only XP
    function storeXP(uint256 _tokenId, uint16 xp) public {
        require(_checkTokenWriteAuth(_tokenId) || _permissionsAllow[msg.sender] & 0x1 == 1, "not authorized");
        // Slot 2 offset 0: 16 bit value
        uint256 cleared = uint256(_metadataStorage[_tokenId][0]) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000;
        _metadataStorage[_tokenId][0] = cleared | uint256(xp);
    }

    // Load Only XP
    function loadXP(uint256 _tokenId) public view returns (uint16) {
        return uint16(uint256(_metadataStorage[_tokenId][0]));
    }

    // Store Only level
    function storeLevel(uint256 _tokenId, uint8 level) public {
        require(_checkTokenWriteAuth(_tokenId) || _permissionsAllow[msg.sender] & 0x2 == 2, "not authorized");
        // Slot 2 offset 16: 16 bit value
        uint256 cleared = uint256(_metadataStorage[_tokenId][0]) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFF;
        _metadataStorage[_tokenId][0] = cleared | (uint256(level) << 16);
    }

    // Load Only level
    function loadLevel(uint256 tokenId) public view returns (uint16) {
        return uint16(uint256(_metadataStorage[tokenId][2]) >> 16);
    }

    function addReference(uint256 ourTokenId, uint64 liteRef) public override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        PatchworkDynamicRefs.addReference(liteRef, _dynamicLiterefStorage[ourTokenId]);
    }

    function addReferenceBatch(uint256 ourTokenId, uint64[] calldata liteRefs) public override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        PatchworkDynamicRefs.addReferenceBatch(liteRefs,  _dynamicLiterefStorage[ourTokenId]);
    }

    function removeReference(uint256 ourTokenId, uint64 liteRef) public override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        PatchworkDynamicRefs.removeReference(liteRef, _dynamicLiterefStorage[ourTokenId]);
    }

    function addReference(uint256 tokenId, uint64 liteRef, uint256 targetMetadataId) public override {
        if (targetMetadataId != 0) {
            revert("Unsupported metadata ID");
        }
        addReference(tokenId, liteRef);
    }


    function removeReference(uint256 tokenId, uint64 liteRef, uint256 targetMetadataId) public override {
        if (targetMetadataId != 0) {
            revert("Unsupported metadata ID");
        }
        removeReference(tokenId, liteRef);
    }

    function addReferenceBatch(uint256 tokenId, uint64[] calldata liteRefs, uint256 targetMetadataId) public override {
        if (targetMetadataId != 0) {
            revert("Unsupported metadata ID");
        }
        addReferenceBatch(tokenId, liteRefs);
    }

    function loadReferenceAddressAndTokenId(uint256 ourTokenId, uint256 idx) public view returns (address addr, uint256 tokenId) {
        uint64 ref = PatchworkDynamicRefs.loadRef(idx, _dynamicLiterefStorage[ourTokenId]);
        (addr, tokenId) = getReferenceAddressAndTokenId(ref);
    }

    function getDynamicReferenceCount(uint256 tokenId) public view override returns (uint256 count) {
        count = PatchworkDynamicRefs.getDynamicReferenceCount(_dynamicLiterefStorage[tokenId]);
    }

    function loadDynamicReferencePage(uint256 tokenId, uint256 offset, uint256 count) public view override returns (address[] memory addresses, uint256[] memory tokenIds) {
        uint64[] memory refs = PatchworkDynamicRefs.loadRefPage(offset, count, _dynamicLiterefStorage[tokenId]);
        addresses = new address[](refs.length);
        tokenIds = new uint256[](refs.length);
        for (uint256 i = 0; i < refs.length; i++) {
            (address attributeAddress, uint256 attributeTokenId) = getReferenceAddressAndTokenId(refs[i]);
            addresses[i] = attributeAddress;
            tokenIds[i] = attributeTokenId;
        }
    }

    function _checkWriteAuth() internal override(Patchwork721, PatchworkLiteRef) view returns (bool allow) {
        return Patchwork721._checkWriteAuth();
    }

    function burn(uint256 tokenId) public {
        // test only
        _burn(tokenId);
    }
}