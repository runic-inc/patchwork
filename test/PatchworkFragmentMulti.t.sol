// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/sampleNFTs/TestFragmentLiteRefNFT.sol";
import "../src/sampleNFTs/TestBaseNFT.sol";
import "../src/sampleNFTs/TestMultiFragmentNFT.sol";

contract PatchworkFragmentMultiTest is Test {
    PatchworkProtocol _prot;
    TestFragmentLiteRefNFT _testFragmentLiteRefNFT;
    TestMultiFragmentNFT _testMultiNFT;

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

        _testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(address(_prot));
        _testMultiNFT = new TestMultiFragmentNFT(address(_prot));

        vm.stopPrank();
        vm.prank(_userAddress);
    }

    function testScopeName() public {
        assertEq(_scopeName, _testMultiNFT.getScopeName());
    }
    
    function testSupportsInterface() public {
        assertTrue(_testMultiNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(_testMultiNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(_testMultiNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(_testMultiNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(_testMultiNFT.supportsInterface(type(IPatchworkNFT).interfaceId));
        assertTrue(_testMultiNFT.supportsInterface(type(IPatchworkAssignableNFT).interfaceId));
        assertTrue(_testMultiNFT.supportsInterface(type(IPatchworkMultiAssignableNFT).interfaceId));
    }

    function testMultiAssign() public {
        vm.startPrank(_scopeOwner);
        uint256 m1 = _testMultiNFT.mint(_user2Address);
        uint256 lr1 = _testFragmentLiteRefNFT.mint(_userAddress);
        uint256 lr2 = _testFragmentLiteRefNFT.mint(_userAddress);
        uint256 lr3 = _testFragmentLiteRefNFT.mint(_userAddress);
        // must be registered
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(_testMultiNFT)));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        // happy path
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testMultiNFT));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        assertTrue(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr1));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        assertTrue(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr2));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr3);
        assertTrue(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr3));
        assertEq(_testMultiNFT.ownerOf(m1), _user2Address);
        // don't allow duplicate
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyAssigned.selector, address(_testMultiNFT), m1));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        // don't allow either owner or random user to unassign
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.unassignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.unassignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(500)));
        vm.prank(address(500));
        _prot.unassignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        vm.startPrank(_scopeOwner);
        // test unassign
        _prot.unassignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        assertFalse(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr2));
        _prot.unassignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        assertFalse(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr1));
        _prot.unassignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr3);
        assertFalse(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr3));
        // test reassign
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        assertTrue(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr2));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr3);
        assertTrue(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr3));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        assertTrue(_testMultiNFT.isAssignedTo(m1, address(_testFragmentLiteRefNFT), lr1));
    }

    function testMultiAssignUserAssign() public {
        vm.startPrank(_scopeOwner);
        // Enable user assign
        _prot.setScopeRules(_scopeName, false, true, false);
        uint256 m1 = _testMultiNFT.mint(_user2Address);
        uint256 lr1 = _testFragmentLiteRefNFT.mint(_userAddress);
        uint256 lr2 = _testFragmentLiteRefNFT.mint(_userAddress);
        // must be registered
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(_testMultiNFT)));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        // happy path
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testMultiNFT));
        // as scope owner, should not revert. Only as user if they don't match, but they should work if they match.
        // should revert
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        // now it should work
        vm.prank(_scopeOwner);
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        vm.prank(_scopeOwner);
        uint256 m2 = _testMultiNFT.mint(_userAddress);
        // This should also work because both are owned by the same user
        vm.prank(_userAddress);
        _prot.assignNFT(address(_testMultiNFT), m2, address(_testFragmentLiteRefNFT), lr2);
    }
    
    function testGetAssignments() public {
        vm.startPrank(_scopeOwner);
        uint256 m1 = _testMultiNFT.mint(_user2Address);
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testMultiNFT));
        uint256[] memory liteRefIds = new uint256[](20);
        for (uint256 i = 0; i < liteRefIds.length; i++) {
            liteRefIds[i] = _testFragmentLiteRefNFT.mint(_userAddress);
            _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), liteRefIds[i]);
        }
        assertEq(20, _testMultiNFT.getAssignmentCount(m1));
        IPatchworkMultiAssignableNFT.Assignment[] memory page1 = _testMultiNFT.getAssignments(m1, 0, 8);
        IPatchworkMultiAssignableNFT.Assignment[] memory page2 = _testMultiNFT.getAssignments(m1, 8, 8);
        IPatchworkMultiAssignableNFT.Assignment[] memory page3 = _testMultiNFT.getAssignments(m1, 16, 8);
        IPatchworkMultiAssignableNFT.Assignment[] memory page4 = _testMultiNFT.getAssignments(m1, 24, 8);
        assertEq(8, page1.length);
        assertEq(8, page2.length);
        assertEq(4, page3.length);
        assertEq(0, page4.length);
        assertEq(page1[0].tokenAddr, address(_testFragmentLiteRefNFT));
        assertEq(page1[0].tokenId, liteRefIds[0]);
        assertEq(page2[0].tokenAddr, address(_testFragmentLiteRefNFT));
        assertEq(page2[0].tokenId, liteRefIds[8]);
        assertEq(page3[0].tokenAddr, address(_testFragmentLiteRefNFT));
        assertEq(page3[0].tokenId, liteRefIds[16]);
    }

    // TODO finish coverage and protocol refactors to complete

}