// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";
import "./nfts/TestDynamicRefLibraryNFT.sol";

contract DynamicRefLibraryNFTTest is Test {

    PatchworkProtocol _prot;

    string _scopeName;
    address _defaultUser;
    address _scopeOwner;
    address _patchworkOwner; 
    address _userAddress;
    address _user2Address;

    function setUp() public {
        _defaultUser = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        _patchworkOwner = 0xF09CFF10D85E70D5AA94c85ebBEbD288756EFEd5;
        _userAddress = 0x10E4017cEd8648A9D5dAc21C82589C03C4835CCc;
        _user2Address = address(550001);
        _scopeOwner = 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5;

        vm.prank(_patchworkOwner);
        _prot = new PatchworkProtocol(_patchworkOwner, address(new PatchworkProtocolAssigner(_patchworkOwner)));

        vm.startPrank(_scopeOwner);
        _scopeName = "testscope";
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        
        vm.stopPrank();
    }

    function testDynamics() public {
        TestDynamicRefLibraryNFT nft = new TestDynamicRefLibraryNFT(address(_prot));
        nft.registerReferenceAddress(address(0x55));
        uint256 m = nft.mint(_userAddress, "");
        assertEq(0, nft.getDynamicReferenceCount(m));
        for (uint256 i = 0; i < 9; i++) {
            (uint64 ref,) = nft.getLiteReference(address(0x55), i);
            nft.addReference(m, ref);
            assertEq(i+1, nft.getDynamicReferenceCount(m));
        }

        (, uint256[] memory tokenIds) = nft.loadDynamicReferencePage(m, 0, 3);
        assertEq(tokenIds[0], 0);
        assertEq(tokenIds[1], 1);
        assertEq(tokenIds[2], 2);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 3, 3);
        assertEq(tokenIds[0], 3);
        assertEq(tokenIds[1], 4);
        assertEq(tokenIds[2], 5);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 6, 4);
        assertEq(tokenIds[0], 6);
        assertEq(tokenIds[1], 7);
        assertEq(tokenIds[2], 8);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 9, 4);
        assertEq(tokenIds.length, 0);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 10, 4);
        assertEq(tokenIds.length, 0);
        for (uint256 i = 0; i < 9; i++) {
            (uint64 ref,) = nft.getLiteReference(address(0x55), i);
            nft.removeReference(m, ref);
            assertEq(8-i, nft.getDynamicReferenceCount(m));
        }
    }

    function testBatchAdd() public {
        TestDynamicRefLibraryNFT nft = new TestDynamicRefLibraryNFT(address(_prot));
        nft.registerReferenceAddress(address(0x55));
        uint256 m = nft.mint(_userAddress, "");
        assertEq(0, nft.getDynamicReferenceCount(m));
        uint64[] memory refs = new uint64[](11);
        for (uint256 i = 0; i < 11; i++) {
            (uint64 ref,) = nft.getLiteReference(address(0x55), i);
            refs[i] = ref;
        }
        nft.addReferenceBatch(m, refs);
        assertEq(11, nft.getDynamicReferenceCount(m));

        (, uint256[] memory tokenIds) = nft.loadDynamicReferencePage(m, 0, 3);
        assertEq(tokenIds[0], 0);
        assertEq(tokenIds[1], 1);
        assertEq(tokenIds[2], 2);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 3, 3);
        assertEq(tokenIds[0], 3);
        assertEq(tokenIds[1], 4);
        assertEq(tokenIds[2], 5);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 6, 5);
        assertEq(tokenIds[0], 6);
        assertEq(tokenIds[1], 7);
        assertEq(tokenIds[2], 8);
        assertEq(tokenIds[3], 9);
        assertEq(tokenIds[4], 10);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 11, 4);
        assertEq(tokenIds.length, 0);
        (, tokenIds) = nft.loadDynamicReferencePage(m, 13, 4);
        assertEq(tokenIds.length, 0);
        for (uint256 i = 0; i < 11; i++) {
            (uint64 ref,) = nft.getLiteReference(address(0x55), i);
            nft.removeReference(m, ref);
            assertEq(10-i, nft.getDynamicReferenceCount(m));
        }
    }

    function testUnusedFuncs() public {
        TestDynamicRefLibraryNFT nft = new TestDynamicRefLibraryNFT(address(_prot));
        nft.loadAllStaticReferences(0);
    }


}