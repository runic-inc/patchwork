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
        uint256 m1 = _testMultiNFT.mint(_userAddress);
        uint256 lr1 = _testFragmentLiteRefNFT.mint(_userAddress);
        uint256 lr2 = _testFragmentLiteRefNFT.mint(_userAddress);
        uint256 lr3 = _testFragmentLiteRefNFT.mint(_userAddress);
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testMultiNFT));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr1);
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr3);
        // don't allow duplicate
        // TODO I don't like this "in scope" business because with this model it should be regardless of scope.
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyAssignedInScope.selector, _scopeName, address(_testMultiNFT), m1));
        _prot.assignNFT(address(_testMultiNFT), m1, address(_testFragmentLiteRefNFT), lr2);
        
    }
}