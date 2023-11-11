// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "./nfts/TestDynamicArrayLiteRefNFT.sol";

contract PatchworkAccountPatchTest is Test {

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
        _prot = new PatchworkProtocol();

        vm.startPrank(_scopeOwner);
        _scopeName = "testscope";
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        
        vm.stopPrank();
    }

    function testDynamics() public {
        TestDynamicArrayLiteRefNFT nft = new TestDynamicArrayLiteRefNFT(address(_prot));
        uint256 m = nft.mint(_userAddress);
        assertEq(0, nft.getReferenceCount(m));
        nft.addReference(m, 0x1);
        assertEq(1, nft.getReferenceCount(m));
        nft.addReference(m, 0x50);
        assertEq(2, nft.getReferenceCount(m));
        nft.addReference(m, 0x51);
        assertEq(3, nft.getReferenceCount(m));
        nft.addReference(m, 0x52);
        assertEq(4, nft.getReferenceCount(m));
        nft.addReference(m, 0x53);
        assertEq(5, nft.getReferenceCount(m));
        nft.addReference(m, 0x54);
        assertEq(6, nft.getReferenceCount(m));
        nft.addReference(m, 0x55);
        assertEq(7, nft.getReferenceCount(m));
        nft.addReference(m, 0x56);
        assertEq(8, nft.getReferenceCount(m));
        nft.addReference(m, 0x57);
        assertEq(9, nft.getReferenceCount(m));

        nft.removeReference(m, 0x1);
        assertEq(8, nft.getReferenceCount(m));
        nft.removeReference(m, 0x50);
        assertEq(7, nft.getReferenceCount(m));
        nft.removeReference(m, 0x51);
        assertEq(6, nft.getReferenceCount(m));
        nft.removeReference(m, 0x52);
        assertEq(5, nft.getReferenceCount(m));
        nft.removeReference(m, 0x53);
        assertEq(4, nft.getReferenceCount(m));
        nft.removeReference(m, 0x54);
        assertEq(3, nft.getReferenceCount(m));
        nft.removeReference(m, 0x55);
        assertEq(2, nft.getReferenceCount(m));
        nft.removeReference(m, 0x56);
        assertEq(1, nft.getReferenceCount(m));
        nft.removeReference(m, 0x57);
        assertEq(0, nft.getReferenceCount(m));
    }


}