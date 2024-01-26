// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";
import "./nfts/TestPatchLiteRefNFT.sol";
import "./nfts/TestBaseNFT.sol";
import "./nfts/TestPatchFragmentNFT.sol";

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

        PatchworkProtocolAssigner assigner = new PatchworkProtocolAssigner(_patchworkOwner);
        _prot = new PatchworkProtocol(_patchworkOwner, address(assigner));
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

    function testSupportsInterface() public {
        assertTrue(_testPatchLiteRefNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(_testPatchLiteRefNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(_testPatchLiteRefNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(_testPatchLiteRefNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(_testPatchLiteRefNFT.supportsInterface(type(IPatchwork721).interfaceId));
        assertTrue(_testPatchLiteRefNFT.supportsInterface(type(IPatchworkLiteRef).interfaceId));
        assertTrue(_testPatchLiteRefNFT.supportsInterface(type(IPatchworkPatch).interfaceId));
        assertFalse(_testPatchLiteRefNFT.supportsInterface(type(IPatchworkReversiblePatch).interfaceId));
        TestPatchFragmentNFT testPatchFragmentNFT = new TestPatchFragmentNFT(address(_prot));
        assertTrue(testPatchFragmentNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(testPatchFragmentNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(testPatchFragmentNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(testPatchFragmentNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(testPatchFragmentNFT.supportsInterface(type(IPatchwork721).interfaceId));
        assertTrue(testPatchFragmentNFT.supportsInterface(type(IPatchworkPatch).interfaceId));
        assertTrue(testPatchFragmentNFT.supportsInterface(type(IPatchworkReversiblePatch).interfaceId));
    }

    function testLocks() public {
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        bool locked = _testPatchLiteRefNFT.locked(patchTokenId);
        assertFalse(locked);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.CannotLockSoulboundPatch.selector, _testPatchLiteRefNFT));
        _testPatchLiteRefNFT.setLocked(patchTokenId, true);
    }
    
    function testBurn() public {
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        _testPatchLiteRefNFT.burn(patchTokenId);
        // Should be able to re-patch now
        vm.prank(_scopeOwner);
        patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
    }

    function testOtherOwnerDisallowed() public {
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        _prot.patch(_user2Address, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
    }

    function testPatchFragment() public {
        vm.startPrank(_scopeOwner);
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        uint256 baseTokenId2 = _testBaseNFT.mint(_user2Address);
        uint256 baseTokenId3 = _testBaseNFT.mint(_userAddress);
        TestPatchFragmentNFT testPatchFragmentNFT = new TestPatchFragmentNFT(address(_prot));
        _testPatchLiteRefNFT.registerReferenceAddress(address(testPatchFragmentNFT));
        uint256 liteRefId = _prot.patch(_userAddress, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        uint256 liteRefId2 = _prot.patch(_user2Address, address(_testBaseNFT), baseTokenId2, address(_testPatchLiteRefNFT));
        uint256 fragmentTokenId = _prot.patch(_userAddress, address(_testBaseNFT), baseTokenId3, address(testPatchFragmentNFT));
        // check reverse lookups
        assertEq(fragmentTokenId, testPatchFragmentNFT.getTokenIdByTarget(IPatchworkPatch.PatchTarget(address(_testBaseNFT), baseTokenId3)));
        // cannot assign patch to a literef that this person does not own
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _scopeOwner));
        _prot.assign(address(testPatchFragmentNFT), fragmentTokenId, address(_testPatchLiteRefNFT), liteRefId2);
        // can assign to same owner
        _prot.assign(address(testPatchFragmentNFT), fragmentTokenId, address(_testPatchLiteRefNFT), liteRefId);
        // transfer the underlying patched nft and check ownership
        vm.stopPrank();
        assertEq(_userAddress, _testBaseNFT.ownerOf(baseTokenId));
        assertEq(_userAddress, _testPatchLiteRefNFT.ownerOf(baseTokenId));
        assertEq(_userAddress, testPatchFragmentNFT.ownerOf(fragmentTokenId));
        vm.prank(_userAddress);
        _testBaseNFT.transferFrom(_userAddress, _user2Address, baseTokenId);
        assertEq(_user2Address, _testBaseNFT.ownerOf(baseTokenId));
        assertEq(_user2Address, _testPatchLiteRefNFT.ownerOf(baseTokenId));
        assertEq(_userAddress, testPatchFragmentNFT.ownerOf(fragmentTokenId));
        vm.prank(_userAddress);
        _testBaseNFT.transferFrom(_userAddress, _user2Address, baseTokenId3);
        assertEq(_user2Address, testPatchFragmentNFT.ownerOf(fragmentTokenId));
        _prot.updateOwnershipTree(address(testPatchFragmentNFT), fragmentTokenId);
        assertEq(_user2Address, testPatchFragmentNFT.ownerOf(fragmentTokenId));
    }
}