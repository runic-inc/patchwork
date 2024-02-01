// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";
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
        _prot = new PatchworkProtocol(_patchworkOwner, address(new PatchworkProtocolAssigner(_patchworkOwner)));
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
        assertTrue(_testPatchworkNFT.supportsInterface(type(IPatchwork721).interfaceId));
    }

    function testLoadStorePackedMetadataSlot() public {
        uint256 n = _testPatchworkNFT.mint(_userAddress, "");
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchworkNFT.storePackedMetadataSlot(n, 0, 0x505050);
        vm.prank(_scopeOwner);
        _testPatchworkNFT.storePackedMetadataSlot(n, 0, 0x505050);
        assertEq(0x505050, _testPatchworkNFT.loadPackedMetadataSlot(n, 0));
    }

    function testLoadStorePackedMetadata() public {
        uint256 n = _testPatchworkNFT.mint(_userAddress, "");
        uint256[] memory slots = _testPatchworkNFT.loadPackedMetadata(n);
        slots[0] = 0x505050;
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchworkNFT.storePackedMetadata(n, slots);
        vm.prank(_scopeOwner);
        _testPatchworkNFT.storePackedMetadata(n, slots);
        slots = _testPatchworkNFT.loadPackedMetadata(n);
        assertEq(0x505050, slots[0]);
    }

    function testTransferFrom() public {
        // TODO make sure these are calling checkTransfer on proto
        uint256 n = _testPatchworkNFT.mint(_userAddress, "");
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(n));
        vm.prank(_userAddress);
        _testPatchworkNFT.transferFrom(_userAddress, _user2Address, n);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.prank(_user2Address);
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, n);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(n));
        vm.prank(_userAddress);
        _testPatchworkNFT.safeTransferFrom(_userAddress, _user2Address, n, bytes("abcd"));
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));

        // test wrong user revert
        vm.startPrank(_userAddress);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, _userAddress, n));
        _testPatchworkNFT.transferFrom(_user2Address, _userAddress, n);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, _userAddress, n));
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, n);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, _userAddress, n));
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, n, bytes("abcd"));
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
    }

    function testLockFreezeSeparation() public {
        uint256 n = _testPatchworkNFT.mint(_userAddress, "");
        vm.startPrank(_userAddress);
        assertFalse(_testPatchworkNFT.locked(n));
        _testPatchworkNFT.setLocked(n, true);
        assertTrue(_testPatchworkNFT.locked(n));
        assertFalse(_testPatchworkNFT.frozen(n));
        _testPatchworkNFT.setFrozen(n, true);
        assertTrue(_testPatchworkNFT.frozen(n));
        assertTrue(_testPatchworkNFT.locked(n));
        _testPatchworkNFT.setLocked(n, false);
        assertTrue(_testPatchworkNFT.frozen(n));
        assertFalse(_testPatchworkNFT.locked(n));
        _testPatchworkNFT.setFrozen(n, false);
        assertFalse(_testPatchworkNFT.frozen(n));
        assertFalse(_testPatchworkNFT.locked(n));
        _testPatchworkNFT.setFrozen(n, true);
        assertTrue(_testPatchworkNFT.frozen(n));
        assertFalse(_testPatchworkNFT.locked(n));
        _testPatchworkNFT.setLocked(n, true);
        assertTrue(_testPatchworkNFT.frozen(n));
        assertTrue(_testPatchworkNFT.locked(n));
    }

    function testTransferFromWithFreezeNonce() public {
        // TODO make sure these are calling checkTransfer on proto
        uint256 n = _testPatchworkNFT.mint(_userAddress, "");
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchworkNFT.setFrozen(n, true);
        vm.prank(_userAddress);
        _testPatchworkNFT.setFrozen(n, true);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(n));
        vm.prank(_userAddress);
        _testPatchworkNFT.transferFromWithFreezeNonce(_userAddress, _user2Address, n, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.prank(_user2Address);
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, n, 0);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(n));
        vm.prank(_userAddress);
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_userAddress, _user2Address, n, bytes("abcd"), 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));

        vm.startPrank(_user2Address);
        // test not frozen revert
        _testPatchworkNFT.setFrozen(n, false);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, n));
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, n, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, n));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, n, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, n));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, n, bytes("abcd"), 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));

        // test incorrect nonce revert
        _testPatchworkNFT.setFrozen(n, true);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, n, 0));
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, n, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, n, 0));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, n, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, n, 0));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, n, bytes("abcd"), 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.stopPrank();

        // test wrong user revert
        vm.startPrank(_userAddress);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, _userAddress, n));
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, n, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, _userAddress, n));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, n, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, _userAddress, n));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, n, bytes("abcd"), 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(n));
        vm.stopPrank();
    }
}