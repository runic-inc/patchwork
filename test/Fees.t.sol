// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "./nfts/Test1155PatchNFT.sol";
import "./nfts/TestBase1155.sol";

contract FeesTest is Test {

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

    function testProtocolBankers() public {
        vm.expectRevert(); // caller is not owner
        _prot.addProtocolBanker(_defaultUser);
        vm.prank(_patchworkOwner);
        _prot.addProtocolBanker(_user2Address);
        // TODO set up a mint to make some money
        vm.expectRevert();
        _prot.withdrawFromProtocol(0);
        vm.prank(_user2Address); // TODO test owner too
        _prot.withdrawFromProtocol(0);
    }
}