// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "./nfts/TestPatchworkNFT.sol";

contract PatchworkNFTTest is Test {
    PatchworkProtocol _prot;
    TestPatchworkNFT _testPatchworkNFT;

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

        _testPatchworkNFT = new TestPatchworkNFT(address(_prot));
        vm.stopPrank();
    }

    function testScopeName() public {
        assertEq(_scopeName, _testPatchworkNFT.getScopeName());
    }

    function testSupportsInterface() public {
        assertTrue(_testPatchworkNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(_testPatchworkNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(_testPatchworkNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(_testPatchworkNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(_testPatchworkNFT.supportsInterface(type(IPatchworkNFT).interfaceId));
    }

    function testLoadStorePackedMetadataSlot() public {
        _testPatchworkNFT.mint(_userAddress, 1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchworkNFT.storePackedMetadataSlot(1, 0, 0x505050);
        vm.prank(_scopeOwner);
        _testPatchworkNFT.storePackedMetadataSlot(1, 0, 0x505050);
        assertEq(0x505050, _testPatchworkNFT.loadPackedMetadataSlot(1, 0));
    }

    function testTransferFrom() public {
        // TODO make sure these are calling checkTransfer on proto
        _testPatchworkNFT.mint(_userAddress, 1);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.transferFrom(_userAddress, _user2Address, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.prank(_user2Address);
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, 1);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.safeTransferFrom(_userAddress, _user2Address, 1, bytes("abcd"));
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        // test wrong user revert
        vm.startPrank(_userAddress);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.transferFrom(_user2Address, _userAddress, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, 1, bytes("abcd"));
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
    }

    function testLockFreezeSeparation() public {
        _testPatchworkNFT.mint(_userAddress, 1);
        vm.startPrank(_userAddress);
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setLocked(1, true);
        assertTrue(_testPatchworkNFT.locked(1));
        assertFalse(_testPatchworkNFT.frozen(1));
        _testPatchworkNFT.setFrozen(1, true);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertTrue(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setLocked(1, false);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setFrozen(1, false);
        assertFalse(_testPatchworkNFT.frozen(1));
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setFrozen(1, true);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setLocked(1, true);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertTrue(_testPatchworkNFT.locked(1));
    }

    function testTransferFromWithFreezeNonce() public {
        // TODO make sure these are calling checkTransfer on proto
        _testPatchworkNFT.mint(_userAddress, 1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchworkNFT.setFrozen(1, true);
        vm.prank(_userAddress);
        _testPatchworkNFT.setFrozen(1, true);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.transferFromWithFreezeNonce(_userAddress, _user2Address, 1, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.prank(_user2Address);
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 0);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_userAddress, _user2Address, 1, bytes("abcd"), 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        vm.startPrank(_user2Address);
        // test not frozen revert
        _testPatchworkNFT.setFrozen(1, false);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, 1));
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, 1));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, 1));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, bytes("abcd"), 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        // test incorrect nonce revert
        _testPatchworkNFT.setFrozen(1, true);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, 1, 0));
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, 1, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, 1, 0));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, 1, 0));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, bytes("abcd"), 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.stopPrank();

        // test wrong user revert
        vm.startPrank(_userAddress);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, bytes("abcd"), 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.stopPrank();
    }
}