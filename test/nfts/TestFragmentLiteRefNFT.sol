// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/PatchworkFragmentSingle.sol";
import "../../src/PatchworkLiteRef.sol";
import "../../src/interfaces/IPatchworkMintable.sol";

enum FragmentType {
    BASE,
    MOUTH,
    EYES,
    HAT
}

struct TestFragmentLiteRefNFTMetadata {
    uint64[8] artifactIDs;
    FragmentType fragmentType;
    uint8 rarity;
    string name;
}

contract TestFragmentLiteRefNFT is PatchworkFragmentSingle, PatchworkLiteRef, IPatchworkMintable {

    uint256 _nextTokenId;
    bool _testLockOverride;
    bool _getLiteRefOverrideSet;
    uint64 _getLiteRefOverride;
    bool _getAssignedToOverrideSet;
    address _getAssignedToOverride;

    constructor (address _manager) Patchwork721("testscope", "TestFragmentLiteRef", "TFLR", _manager, msg.sender) {
    }

    // ERC-165
    function supportsInterface(bytes4 interfaceID) public view virtual override(PatchworkFragmentSingle, PatchworkLiteRef) returns (bool) {
        return PatchworkLiteRef.supportsInterface(interfaceID) || 
            PatchworkFragmentSingle.supportsInterface(interfaceID) ||
            interfaceID == type(IPatchworkMintable).interfaceId;
    }

    function mint(address to, bytes calldata /* data */) public payable returns (uint256 tokenId) {
        if (msg.value > 0) {
            revert();
        }
        tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        _metadataStorage[tokenId] = new uint256[](3);
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

    function schemaURI() pure external returns (string memory) {
        return "https://mything/my-fragment-metadata.json";
    }

    function imageURI(uint256 tokenId) pure external returns (string memory) {
        return string.concat("https://mything/my/", Strings.toString(tokenId), ".png");
    }
    
    /*
    Hard coded prototype schema is:
    slot 0 offset 0 = fragmentType
    slot 0 offset 8 = rarity
    slot 0 offset 16 = name
    slot 0 offset 144 = <next open>
    */
    function schema() pure external returns (MetadataSchema memory) {
        MetadataSchemaEntry[] memory entries = new MetadataSchemaEntry[](8);
        entries[0] = MetadataSchemaEntry(0, 0, FieldType.UINT64, 8, FieldVisibility.PUBLIC, 0, 0, "artifactIDs");
        entries[1] = MetadataSchemaEntry(1, 0, FieldType.UINT8, 1, FieldVisibility.PUBLIC, 2, 0, "fragmentType");
        entries[2] = MetadataSchemaEntry(2, 0, FieldType.UINT16, 1, FieldVisibility.PUBLIC, 2, 8, "rarity");
        entries[3] = MetadataSchemaEntry(3, 0, FieldType.CHAR16, 1, FieldVisibility.PUBLIC, 2, 16, "name");
        return MetadataSchema(1, entries);
    }

    function packMetadata(TestFragmentLiteRefNFTMetadata memory data) public pure returns (uint256[] memory slots) {
        bytes32 _name;
        bytes memory ns = bytes(data.name);

        assembly {
            _name := mload(add(ns, 32))
        }
        slots = new uint256[](3);
        slots[0] = uint256(data.artifactIDs[0]) | uint256(data.artifactIDs[1]) << 64 | uint256(data.artifactIDs[2]) << 128 | uint256(data.artifactIDs[3]) << 192;
        slots[1] = uint256(data.artifactIDs[4]) | uint256(data.artifactIDs[5]) << 64 | uint256(data.artifactIDs[6]) << 128 | uint256(data.artifactIDs[7]) << 192;
        slots[2] = uint256(data.fragmentType) | uint256(data.rarity) << 8 | uint256(_name) >> 128 << 16;
        return slots;
    }

    function storeMetadata(uint256 _tokenId, TestFragmentLiteRefNFTMetadata memory data) public {
        require(_checkTokenWriteAuth(_tokenId), "not authorized");
        _metadataStorage[_tokenId] = packMetadata(data);
    }

    function unpackMetadata(uint256[] memory slots) public pure returns (TestFragmentLiteRefNFTMetadata memory data) {
        data.artifactIDs[0] = uint64(slots[0]);
        data.artifactIDs[1] = uint64(slots[0] >> 64);
        data.artifactIDs[2] = uint64(slots[0] >> 128);
        data.artifactIDs[3] = uint64(slots[0] >> 192);
        data.artifactIDs[4] = uint64(slots[1]);
        data.artifactIDs[5] = uint64(slots[1] >> 64);
        data.artifactIDs[6] = uint64(slots[1] >> 128);
        data.artifactIDs[7] = uint64(slots[1] >> 192);
        data.fragmentType = FragmentType(slots[2]);
        data.rarity = uint8(slots[2] >> 8);
        data.name = string(abi.encodePacked(bytes16(uint128(slots[2] >> 16))));
        return data;
    }

    function loadMetadata(uint256 _tokenId) public view returns (TestFragmentLiteRefNFTMetadata memory data) {
        return unpackMetadata(_metadataStorage[_tokenId]);
    }

   function addReference(uint256 ourTokenId, uint64 liteRef) public override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        uint256[] storage mdStorage = _metadataStorage[ourTokenId];
        uint256 slot = mdStorage[0];
        uint256 slot2 = mdStorage[1];
        if (uint64(slot) == 0) {
            mdStorage[0] = slot | liteRef;
        } else if (uint64(slot >> 64) == 0) {
            mdStorage[0] = slot | uint256(liteRef) << 64;
        } else if (uint64(slot >> 128) == 0) {
            mdStorage[0] = slot | uint256(liteRef) << 128;
        } else if (uint64(slot >> 192) == 0) {
            mdStorage[0] = slot | uint256(liteRef) << 192;
        } else if (uint64(slot2) == 0) {
            mdStorage[0] = slot2 | liteRef;
        } else if (uint64(slot2 >> 64) == 0) {
            mdStorage[0] = slot2 | uint256(liteRef) << 64;
        } else if (uint64(slot2 >> 128) == 0) {
            mdStorage[0] = slot2 | uint256(liteRef) << 128;
        } else if (uint64(slot2 >> 192) == 0) {
            mdStorage[0] = slot2 | uint256(liteRef) << 192;
        } else {
            revert("No reference slots available");
        }
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

    function addReferenceBatch(uint256 tokenId, uint64[] calldata liteRefs, uint256 targetMetadataId) public view override {
        if (targetMetadataId != 0) {
            revert("Unsupported metadata ID");
        }
        addReferenceBatch(tokenId, liteRefs);
    }

    function addReferenceBatch(uint256 ourTokenId, uint64[] calldata /*_liteRefs*/) public view override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        // TODO bulk insert for fewer stores
    }

    function removeReference(uint256 ourTokenId, uint64 liteRef) public override {
        require(_checkTokenWriteAuth(ourTokenId), "not authorized");
        uint256[] storage mdStorage = _metadataStorage[ourTokenId];
        uint256 slot = mdStorage[0];
        uint256 slot2 = mdStorage[1];
        if (uint64(slot) == liteRef) {
            mdStorage[0] = slot & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000;
        } else if (uint64(slot >> 64) == liteRef) {
            mdStorage[0] = slot & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF;
        } else if (uint64(slot >> 128) == liteRef) {
            mdStorage[0] = slot & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else if (uint64(slot >> 192) == liteRef) {
            mdStorage[0] = slot & 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else if (uint64(slot2) == liteRef) {
            mdStorage[0] = slot2 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000;
        } else if (uint64(slot2 >> 64) == liteRef) {
            mdStorage[0] = slot2 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF;
        } else if (uint64(slot2 >> 128) == liteRef) {
            mdStorage[0] = slot2 & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else if (uint64(slot2 >> 192) == liteRef) {
            mdStorage[0] = slot2 & 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else {
            revert("not assigned");
        }
    }

    function loadReferenceAddressAndTokenId(uint256 ourTokenId, uint256 idx) public view returns (address addr, uint256 tokenId) {
        uint256[] storage slots = _metadataStorage[ourTokenId];
        uint slotNumber = idx / 4;
        uint shift = (idx % 4) * 64; 
        uint64 attributeId = uint64(slots[slotNumber] >> shift);
        return getReferenceAddressAndTokenId(attributeId);
    }

    function loadAllStaticReferences(uint256 tokenId) public view override returns (address[] memory addresses, uint256[] memory tokenIds) {
        uint256[] storage slots = _metadataStorage[tokenId];
        addresses = new address[](8);
        tokenIds = new uint256[](8);
        for (uint i = 0; i < 8; i++) {
            uint slotNumber = i / 4; // integer division will get the correct slot number
            uint shift = (i % 4) * 64; // the remainder will give the correct shift
            uint64 attributeId = uint64(slots[slotNumber] >> shift);
            (address attributeAddress, uint256 attributeTokenId) = getReferenceAddressAndTokenId(attributeId);
            addresses[i] = attributeAddress;
            tokenIds[i] = attributeTokenId;
        }
        return (addresses, tokenIds);
    }

    function _checkWriteAuth() internal override(Patchwork721, PatchworkLiteRef) view returns (bool allow) {
        return Patchwork721._checkWriteAuth();
    }

    // Function for mocking test behaviors - set to true for it to return unlocked always
    function setTestLockOverride(bool override_) public {
        _testLockOverride = override_;
    }

    // Override to check bad behavior cases
    function locked(uint256 tokenId) public view virtual override returns (bool) {
        if (_testLockOverride) {
            return false;
        }
        return super.locked(tokenId);
    }

    // Testing overrides
    function setGetLiteRefOverride(bool set_, uint64 value_) public {
        _getLiteRefOverrideSet = set_;
        _getLiteRefOverride = value_;
    }

    // Testing overrides
    function getLiteReference(address addr, uint256 tokenId) public virtual override view returns (uint64 liteRef, bool redacted) {
        if (_getLiteRefOverrideSet) {
            return (_getLiteRefOverride, false);
        }
        return super.getLiteReference(addr, tokenId);
    }

    // Testing overrides
    function setGetAssignedToOverride(bool set_, address value_) public {
        _getAssignedToOverrideSet = set_;
        _getAssignedToOverride = value_;
    }

    function getAssignedTo(uint256 ourTokenId) public virtual override view returns (address, uint256) {
        if (_getAssignedToOverrideSet) {
            return (_getAssignedToOverride, 1);
        }
        return super.getAssignedTo(ourTokenId);
    }

    function setScopeName(string memory scopeName) public {
        // For testing only
        _scopeName = scopeName;
    }
}