// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "./nfts/TestAccountPatchNFT.sol";

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

    function testScopeName() public {
        vm.prank(_scopeOwner);
        TestAccountPatchNFT testAccountPatchNFT = new TestAccountPatchNFT(address(_prot), false, false);
        assertEq(_scopeName, testAccountPatchNFT.getScopeName());
    }
    
    function testSupportsInterface() public {
        vm.prank(_scopeOwner);
        TestAccountPatchNFT testAccountPatchNFT = new TestAccountPatchNFT(address(_prot), false, false);
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IPatchwork721).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IPatchworkAccountPatch).interfaceId));
    }

    function testAccountPatchNotSameOwner() public {
        // Not same owner model, yes transferrable
        vm.prank(_scopeOwner);
        TestAccountPatchNFT testAccountPatchNFT = new TestAccountPatchNFT(address(_prot), false, false);
        // User patching is off, not authorized
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.patchAccount(_userAddress, _user2Address, address(testAccountPatchNFT));
        vm.prank(_scopeOwner);
        uint256 tokenId = _prot.patchAccount(_userAddress, _user2Address, address(testAccountPatchNFT));
        assertEq(_userAddress, testAccountPatchNFT.ownerOf(tokenId));
        // Duplicate should fail
        vm.prank(_scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.AccountAlreadyPatched.selector, _user2Address, address(testAccountPatchNFT)));
        _prot.patchAccount(_userAddress, _user2Address, address(testAccountPatchNFT));
        // Test transfer
        vm.prank(_userAddress);
        testAccountPatchNFT.transferFrom(_userAddress, address(55), tokenId);
        vm.prank(address(55));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedOperation.selector));
        testAccountPatchNFT.burn(tokenId);
    }

    function testAccountPatchSameOwner() public {
        // Same owner model, not transferrable
        vm.prank(_scopeOwner);
        TestAccountPatchNFT testAccountPatchNFT = new TestAccountPatchNFT(address(_prot), true, false);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.MintNotAllowed.selector, _userAddress));
        vm.prank(_scopeOwner);
        _prot.patchAccount(_userAddress, _user2Address, address(testAccountPatchNFT));
        vm.prank(_scopeOwner);
        uint256 tokenId = _prot.patchAccount(_userAddress, _userAddress, address(testAccountPatchNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TransferNotAllowed.selector, address(testAccountPatchNFT), tokenId));
        vm.prank(_userAddress);
        testAccountPatchNFT.transferFrom(_userAddress, address(55), tokenId);
    }

    function testAccountPatchUserPatch() public {
        vm.prank(_scopeOwner);
        _prot.setScopeRules(_scopeName, true, false, false);
        // Not same owner model, yes transferrable
        vm.prank(_scopeOwner);
        TestAccountPatchNFT testAccountPatchNFT = new TestAccountPatchNFT(address(_prot), false, false);
        // User patching is on
        _prot.patchAccount(_userAddress, _user2Address, address(testAccountPatchNFT));
    }

    function testReverseLookups() public {
        vm.startPrank(_scopeOwner);
        TestAccountPatchNFT testAccountPatchNFT = new TestAccountPatchNFT(address(_prot), false, true);
        // User patching is on
        uint256 pId = _prot.patchAccount(_userAddress, _user2Address, address(testAccountPatchNFT));
        assertEq(pId, testAccountPatchNFT.getTokenIdForOriginalAccount(_user2Address));
        // disabled case
        TestAccountPatchNFT testAccountPatchNFT2 = new TestAccountPatchNFT(address(_prot), false, false);
        assertEq(0, testAccountPatchNFT2.getTokenIdForOriginalAccount(_user2Address));
    }
}