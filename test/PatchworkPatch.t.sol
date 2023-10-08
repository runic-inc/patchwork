// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/sampleNFTs/TestPatchLiteRefNFT.sol";
import "../src/sampleNFTs/TestBaseNFT.sol";

contract PatchworkPatchTest is Test {
    PatchworkProtocol _prot;
    TestBaseNFT _testBaseNFT;
    TestPatchLiteRefNFT _testPatchLiteRefNFT;

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
        _scopeName = "testscope";
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);

        _testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(_prot)); 

        vm.stopPrank();
        vm.prank(_userAddress);
        _testBaseNFT = new TestBaseNFT();
    }

    function testScopeName() public {
        assertEq(_scopeName, _testPatchLiteRefNFT.getScopeName());
    }

    function testLocks() public {
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        uint256 patchTokenId = _prot.createPatch(address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        bool locked = _testPatchLiteRefNFT.locked(patchTokenId);
        assertFalse(locked);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.CannotLockSoulboundPatch.selector, _testPatchLiteRefNFT));
        _testPatchLiteRefNFT.setLocked(patchTokenId, true);
    }
    
    function testBurn() public {
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        uint256 patchTokenId = _prot.createPatch(address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedOperation.selector));
        _testPatchLiteRefNFT.burn(patchTokenId);
    }

    function testPatchworkCompatible() public {
        bytes1 r1 = _testPatchLiteRefNFT.patchworkCompatible_();
        assertEq(0, r1);
    }
}