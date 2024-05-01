// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";
import "./nfts/TestFragmentLiteRefNFT.sol";
import "./nfts/TestBaseNFT.sol";

contract PatchworkFragmentSingleTest is Test {
    PatchworkProtocol _prot;
    TestFragmentLiteRefNFT _testFragmentLiteRefNFT;

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

        _testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(address(_prot));

        vm.stopPrank();
    }

    function testScopeName() public {
        assertEq(_scopeName, _testFragmentLiteRefNFT.getScopeName());
    }
    
    function testSupportsInterface() public {
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IPatchworkScoped).interfaceId));
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IPatchwork721).interfaceId));
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IPatchworkAssignable).interfaceId));
        assertTrue(_testFragmentLiteRefNFT.supportsInterface(type(IPatchworkSingleAssignable).interfaceId));
    }

    function testOnAssignedTransferError() public {
        vm.expectRevert();
        _testFragmentLiteRefNFT.onAssignedTransfer(address(0), address(1), 1);
    }

    function testNotAssignedUnassign() public {
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentNotAssigned.selector, address(_testFragmentLiteRefNFT), 5));
        vm.prank(_scopeOwner);
        _testFragmentLiteRefNFT.unassign(5);
    }
    
    function testLiteref56bitlimit() public {
        vm.prank(_scopeOwner);
        uint8 r1 = _testFragmentLiteRefNFT.registerReferenceAddress(address(1));
        (uint64 ref, bool redacted) = _testFragmentLiteRefNFT.getLiteReference(address(1), 1);
        assertEq((uint256(r1) << 56) + 1, ref);
        (ref, redacted) = _testFragmentLiteRefNFT.getLiteReference(address(1), 0xFFFFFFFFFFFFFF);
        assertEq((uint256(r1) << 56) + 0xFFFFFFFFFFFFFF, ref);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedTokenId.selector, 1 << 56));
        _testFragmentLiteRefNFT.getLiteReference(address(1), 1 << 56);
    }
}