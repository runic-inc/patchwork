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
import "./nfts/TestBaseNFT.sol";

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
        vm.deal(_scopeOwner, 2 ether);
    }

    function testProtocolBankers() public {
        vm.expectRevert("Ownable: caller is not the owner"); // caller is not owner
        _prot.addProtocolBanker(_defaultUser);
        vm.prank(_patchworkOwner);
        _prot.addProtocolBanker(_user2Address);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.setProtocolFeeConfig(IPatchworkProtocol.ProtocolFeeConfig(1000, 1000, 1000));
        vm.prank(_patchworkOwner);
        _prot.setProtocolFeeConfig(IPatchworkProtocol.ProtocolFeeConfig(150, 150, 150));
        IPatchworkProtocol.ProtocolFeeConfig memory feeConfig = _prot.getProtocolFeeConfig();
        assertEq(150, feeConfig.mintBp);
        assertEq(150, feeConfig.assignBp);
        assertEq(150, feeConfig.patchBp);
        vm.prank(_user2Address);
        _prot.setProtocolFeeConfig(IPatchworkProtocol.ProtocolFeeConfig(1000, 1000, 1000));


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

    function testPatchFees() public {
        vm.startPrank(_scopeOwner);
        _prot.setScopeRules(_scopeName, false, false, true);
        TestBaseNFT tBase = new TestBaseNFT();
        TestBase1155 tBase1155 = new TestBase1155();
        TestPatchLiteRefNFT t721 = new TestPatchLiteRefNFT(address(_prot));
        Test1155PatchNFT t1155 = new Test1155PatchNFT(address(_prot), false);
        TestAccountPatchNFT tAccount = new TestAccountPatchNFT(address(_prot), false, false);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.setPatchFee(address(tBase), 1);
        vm.stopPrank();

        // 721
        _testPatchFees(address(t721));
        vm.startPrank(_scopeOwner);
        uint256 tId = tBase.mint(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.patch(_userAddress, address(tBase), tId, address(t721));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.patch{value: 1 ether}(_userAddress, address(tBase), tId, address(t721));
        _prot.patch{value: _prot.getPatchFee(address(t721))}(_userAddress, address(tBase), tId, address(t721));
        vm.stopPrank();

        // 1155
        _testPatchFees(address(t1155));
        vm.startPrank(_scopeOwner);
        tId = tBase1155.mint(_userAddress, 1, 1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.patch1155(_userAddress, address(tBase1155), tId, _userAddress, address(t1155));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.patch1155{value: 1 ether}(_userAddress, address(tBase1155), tId, _userAddress, address(t1155));
        _prot.patch1155{value: _prot.getPatchFee(address(t1155))}(_userAddress, address(tBase1155), tId, _userAddress, address(t1155));
        vm.stopPrank();

        // account
        _testPatchFees(address(tAccount));
        vm.startPrank(_scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.patchAccount(_userAddress, _user2Address, address(tAccount));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.patchAccount{value: 1 ether}(_userAddress, _user2Address, address(tAccount));
        _prot.patchAccount{value: _prot.getPatchFee(address(tAccount))}(_userAddress, _user2Address, address(tAccount));
        vm.stopPrank();

        // patch wrong types
        vm.startPrank(_scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.patch(_userAddress, address(tBase), 2, address(t1155));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.patch1155(_userAddress, address(tBase1155), 3, address(0), address(t721));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.patchAccount(_userAddress, _user2Address, address(t721));
    }

    function _testPatchFees(address patchAddr) private {
        vm.startPrank(_scopeOwner);
        // error cases
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, patchAddr));
        _prot.setPatchFee(patchAddr, 1);
        _prot.addWhitelist(_scopeName, patchAddr);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.setPatchFee(patchAddr, 1);
        // success
        vm.startPrank(_scopeOwner);
        _prot.setPatchFee(patchAddr, 1);
        vm.stopPrank();
        assertEq(1, _prot.getPatchFee(patchAddr));
    }

    function testAssignFees() public {
        vm.startPrank(_scopeOwner);
        _prot.setScopeRules(_scopeName, false, false, true);
        TestFragmentLiteRefNFT nft = new TestFragmentLiteRefNFT(address(_prot));
        nft.registerReferenceAddress(address(nft));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(nft)));
        _prot.setAssignFee(address(nft), 1);
        _prot.addWhitelist(_scopeName, address(nft));
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.setAssignFee(address(nft), 1);
        // success
        vm.startPrank(_scopeOwner);
        _prot.setAssignFee(address(nft), 1);
        assertEq(1, _prot.getAssignFee(address(nft)));
        uint256 n1 = nft.mint(_userAddress, "");
        uint256 n2 = nft.mint(_userAddress, "");
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.assign(address(nft), n2, address(nft), n1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.assign{value: 1 ether}(address(nft), n2, address(nft), n1);
        _prot.assign{value: _prot.getAssignFee(address(nft))}(address(nft), n2, address(nft), n1);
    }
}