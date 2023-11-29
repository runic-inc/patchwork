// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "./nfts/Test1155PatchNFT.sol";
import "./nfts/TestBase1155.sol";
import "./nfts/TestFragmentLiteRefNFT.sol";
import "./nfts/TestDynamicArrayLiteRefNFT.sol";
import "./nfts/TestMultiFragmentNFT.sol";
import "./nfts/TestPatchLiteRefNFT.sol";
import "./nfts/TestAccountPatchNFT.sol";

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
        vm.prank(_patchworkOwner);
        _prot.setProtocolFeeConfig(IPatchworkProtocol.ProtocolFeeConfig(1000, 1000, 1000)); // 10%, 10%, 10%

        vm.startPrank(_scopeOwner);
        _scopeName = "testscope";
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        vm.stopPrank();
    }

    function testProtocolBankers() public {
        vm.expectRevert("Ownable: caller is not the owner"); // caller is not owner
        _prot.addProtocolBanker(_defaultUser);
        vm.prank(_patchworkOwner);
        _prot.addProtocolBanker(_user2Address);
        vm.startPrank(_scopeOwner);
        TestFragmentLiteRefNFT lr = new TestFragmentLiteRefNFT(address(_prot));
        _prot.addWhitelist(_scopeName, address(lr));
        _prot.setMintConfiguration(address(lr), IPatchworkProtocol.MintConfig(1000000000, true));
        vm.stopPrank();
        // mint something just to get some money in the account
        IPatchworkProtocol.MintConfig memory mc = _prot.getMintConfiguration(address(lr));
        uint256 mintCost = mc.flatFee;
        assertEq(1000000000, mintCost);
        _prot.mint{value: mintCost}(_userAddress, address(lr), "");
        assertEq(900000000, _prot.balanceOf(_scopeName));
        assertEq(100000000, _prot.balanceOfProtocol());
        // default user not authorized
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.withdrawFromProtocol(100000000);
        vm.prank(_user2Address); 
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InsufficientFunds.selector));
        _prot.withdrawFromProtocol(500000000);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.withdrawFromProtocol(50000000);
        // banker + owner should work
        vm.prank(_user2Address); 
        _prot.withdrawFromProtocol(50000000);
        // Remove a banker
        vm.expectRevert("Ownable: caller is not the owner");
        _prot.removeProtocolBanker(_user2Address);
        vm.prank(_patchworkOwner);
        _prot.removeProtocolBanker(_user2Address);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address); 
        _prot.withdrawFromProtocol(50000000);
        vm.prank(_patchworkOwner);
        _prot.withdrawFromProtocol(50000000);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InsufficientFunds.selector));
        vm.prank(_patchworkOwner);
        _prot.withdrawFromProtocol(1);
    }

    function testScopeBankers() public {
        vm.startPrank(_scopeOwner);
        TestFragmentLiteRefNFT lr = new TestFragmentLiteRefNFT(address(_prot));
        _prot.addWhitelist(_scopeName, address(lr));
        _prot.setMintConfiguration(address(lr), IPatchworkProtocol.MintConfig(1000000000, true));
        _prot.addBanker(_scopeName, _user2Address);
        vm.stopPrank();
        // mint something just to get some money in the account
        IPatchworkProtocol.MintConfig memory mc = _prot.getMintConfiguration(address(lr));
        uint256 mintCost = mc.flatFee;
        assertEq(1000000000, mintCost);
        _prot.mint{value: mintCost}(_userAddress, address(lr), "");
        assertEq(900000000, _prot.balanceOf(_scopeName));
        assertEq(100000000, _prot.balanceOfProtocol());
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.withdraw(_scopeName, 450000000);
        vm.prank(_user2Address);
        _prot.withdraw(_scopeName, 450000000);
        vm.prank(_scopeOwner);
        _prot.removeBanker(_scopeName, _user2Address);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.withdraw(_scopeName, 450000000);
        // will work and take balance to 0
        vm.prank(_scopeOwner);
        _prot.withdraw(_scopeName, 450000000);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InsufficientFunds.selector));
        vm.prank(_scopeOwner);
        _prot.withdraw(_scopeName, 1);
    }

    function testMints() public {
        vm.startPrank(_scopeOwner);
         _prot.setScopeRules(_scopeName, false, false, true);
        TestFragmentLiteRefNFT lr = new TestFragmentLiteRefNFT(address(_prot));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(lr)));
        _prot.setMintConfiguration(address(lr), IPatchworkProtocol.MintConfig(1000000000, true));
        vm.stopPrank();
        // mint something just to get some money in the account
        IPatchworkProtocol.MintConfig memory mc = _prot.getMintConfiguration(address(lr));
        uint256 mintCost = mc.flatFee;
        assertEq(0, mintCost); // Couldn't be set due to whitelisting
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(lr)));
        _prot.mint{value: mintCost}(_userAddress, address(lr), "");
        assertEq(0, _prot.balanceOf(_scopeName));
        assertEq(0, _prot.balanceOfProtocol());
        // Now whitelisted
        vm.startPrank(_scopeOwner);
        _prot.addWhitelist(_scopeName, address(lr));
        _prot.setMintConfiguration(address(lr), IPatchworkProtocol.MintConfig(1000000000, true));
        vm.stopPrank();
        // mint something just to get some money in the account
        mc = _prot.getMintConfiguration(address(lr));
        mintCost = mc.flatFee;
        assertEq(1000000000, mintCost);
        _prot.mint{value: mintCost}(_userAddress, address(lr), "");
        assertEq(900000000, _prot.balanceOf(_scopeName));
        assertEq(100000000, _prot.balanceOfProtocol());
    }

    function testBatchMints() public {
        vm.startPrank(_scopeOwner);
         _prot.setScopeRules(_scopeName, false, false, true);
        TestFragmentLiteRefNFT lr = new TestFragmentLiteRefNFT(address(_prot));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(lr)));
        _prot.setMintConfiguration(address(lr), IPatchworkProtocol.MintConfig(1000000000, true));
        vm.stopPrank();
        // mint something just to get some money in the account
        IPatchworkProtocol.MintConfig memory mc = _prot.getMintConfiguration(address(lr));
        uint256 mintCost = mc.flatFee;
        assertEq(0, mintCost); // Couldn't be set due to whitelisting
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(lr)));
        _prot.mintBatch{value: mintCost}(_userAddress, address(lr), "", 5);
        assertEq(0, _prot.balanceOf(_scopeName));
        assertEq(0, _prot.balanceOfProtocol());
        // Now whitelisted
        vm.startPrank(_scopeOwner);
        _prot.addWhitelist(_scopeName, address(lr));
        _prot.setMintConfiguration(address(lr), IPatchworkProtocol.MintConfig(1000000000, true));
        vm.stopPrank();
        // mint something just to get some money in the account
        mc = _prot.getMintConfiguration(address(lr));
        mintCost = mc.flatFee * 5;
        assertEq(5000000000, mintCost);
        _prot.mintBatch{value: mintCost}(_userAddress, address(lr), "", 5);
        assertEq(4500000000, _prot.balanceOf(_scopeName));
        assertEq(500000000, _prot.balanceOfProtocol());
    }

    // TODO patch fees
    // TODO assign fees
    
}