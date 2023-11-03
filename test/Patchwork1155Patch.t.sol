// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "./nfts/Test1155PatchNFT.sol";
import "./nfts/TestBase1155.sol";

contract Patchwork1155PatchTest is Test {

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
        Test1155PatchNFT testAccountPatchNFT = new Test1155PatchNFT(address(_prot));
        assertEq(_scopeName, testAccountPatchNFT.getScopeName());
    }
    
    function testSupportsInterface() public {
        vm.prank(_scopeOwner);
        Test1155PatchNFT testAccountPatchNFT = new Test1155PatchNFT(address(_prot));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IPatchworkNFT).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IPatchwork1155Patch).interfaceId));
    }

    function test1155Patch() public {
        vm.startPrank(_scopeOwner);
        Test1155PatchNFT test1155PatchNFT = new Test1155PatchNFT(address(_prot));
        TestBase1155 base1155 = new TestBase1155();
        uint256 b = base1155.mint(_userAddress, 5);
        uint256 patchTokenId = _prot.create1155Patch(_userAddress, address(base1155), b, _userAddress, address(test1155PatchNFT));
    }
}