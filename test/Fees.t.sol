// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";
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

        vm.startPrank(_patchworkOwner);
        _prot = new PatchworkProtocol(_patchworkOwner, address(new PatchworkProtocolAssigner(_patchworkOwner)));
        _prot.proposeProtocolFeeConfig(IPatchworkProtocol.FeeConfig(1000, 1000, 1000)); // 10%, 10%, 10%
        skip(20000000);
        _prot.commitProtocolFeeConfig();
        vm.stopPrank();

        vm.startPrank(_scopeOwner);
        _scopeName = "testscope";
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        vm.stopPrank();
        vm.deal(_scopeOwner, 2 ether);
    }

    function testProtocolBankers() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _defaultUser));
        _prot.addProtocolBanker(_defaultUser);
        vm.prank(_patchworkOwner);
        _prot.addProtocolBanker(_user2Address);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.proposeProtocolFeeConfig(IPatchworkProtocol.FeeConfig(1000, 1000, 1000));

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NoProposedFeeSet.selector));
        vm.prank(_patchworkOwner);
        _prot.commitProtocolFeeConfig();

        vm.prank(_patchworkOwner);
        _prot.proposeProtocolFeeConfig(IPatchworkProtocol.FeeConfig(150, 150, 150));
        IPatchworkProtocol.FeeConfig memory feeConfig = _prot.getProtocolFeeConfig();
        assertEq(1000, feeConfig.mintBp);
        assertEq(1000, feeConfig.assignBp);
        assertEq(1000, feeConfig.patchBp);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.commitProtocolFeeConfig();

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TimelockNotElapsed.selector));
        vm.prank(_patchworkOwner);
        _prot.commitProtocolFeeConfig();

        skip(2000000);
        vm.prank(_patchworkOwner);
        _prot.commitProtocolFeeConfig();

        feeConfig = _prot.getProtocolFeeConfig();
        assertEq(150, feeConfig.mintBp);
        assertEq(150, feeConfig.assignBp);
        assertEq(150, feeConfig.patchBp);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NoProposedFeeSet.selector));
        vm.prank(_patchworkOwner);
        _prot.commitProtocolFeeConfig();

        vm.prank(_user2Address);
        _prot.proposeProtocolFeeConfig(IPatchworkProtocol.FeeConfig(1000, 1000, 1000));

        feeConfig = _prot.getProtocolFeeConfig();
        assertEq(150, feeConfig.mintBp);
        assertEq(150, feeConfig.assignBp);
        assertEq(150, feeConfig.patchBp);

        skip(2000000);
        vm.prank(_patchworkOwner);
        _prot.commitProtocolFeeConfig();

        vm.prank(_patchworkOwner);
        _prot.addProtocolBanker(_defaultUser);
        
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
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress); 
        _prot.withdrawFromProtocol(100000000);
        vm.prank(_user2Address); 
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InsufficientFunds.selector));
        _prot.withdrawFromProtocol(500000000);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.withdrawFromProtocol(50000000);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FailedToSend.selector));
        vm.prank(_defaultUser);
        _prot.withdrawFromProtocol(50000000);
        // banker + owner should work
        vm.prank(_user2Address); 
        _prot.withdrawFromProtocol(50000000);
        // Remove a banker
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _defaultUser));
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
        _prot.addBanker(_scopeName, _defaultUser);
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
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FailedToSend.selector));
        vm.prank(_defaultUser);
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

    function testUnsupportedContracts() public {
        vm.startPrank(_scopeOwner);
        TestBaseNFT tBase = new TestBaseNFT();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.setMintConfiguration(address(tBase), IPatchworkProtocol.MintConfig(1000000000, true));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.getMintConfiguration(address(tBase));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.setPatchFee(address(tBase), 1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.getPatchFee(address(tBase));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.setAssignFee(address(tBase), 1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.getAssignFee(address(tBase));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.mint(_userAddress, address(tBase), "");
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.mintBatch(_userAddress, address(tBase), "", 5);
    }

    function testMints() public {
        vm.startPrank(_scopeOwner);
        TestFragmentLiteRefNFT lr = new TestFragmentLiteRefNFT(address(_prot));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.MintNotActive.selector));
        _prot.mint(_userAddress, address(lr), "");
        _prot.setScopeRules(_scopeName, false, false, true);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(lr)));
        _prot.setMintConfiguration(address(lr), IPatchworkProtocol.MintConfig(1000000000, true));
        vm.stopPrank();
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
        mc = _prot.getMintConfiguration(address(lr));
        mintCost = mc.flatFee;
        assertEq(1000000000, mintCost);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.mint{value: 50}(_userAddress, address(lr), "");
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
        mc = _prot.getMintConfiguration(address(lr));
        mintCost = mc.flatFee * 5;
        assertEq(5000000000, mintCost);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.mintBatch{value: 50}(_userAddress, address(lr), "", 5);
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
        Test1155PatchNFT t1155 = new Test1155PatchNFT(address(_prot));
        TestAccountPatchNFT tAccount = new TestAccountPatchNFT(address(_prot), false);
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

    function testFeeOverrides() public {
        vm.startPrank(_scopeOwner);
        _prot.setScopeRules(_scopeName, false, false, true);
        TestBaseNFT tBase = new TestBaseNFT();
        TestPatchLiteRefNFT t721 = new TestPatchLiteRefNFT(address(_prot));
        TestFragmentLiteRefNFT fragLr = new TestFragmentLiteRefNFT(address(_prot));
        _prot.addWhitelist(_scopeName, address(tBase));
        _prot.addWhitelist(_scopeName, address(t721));
        _prot.addWhitelist(_scopeName, address(fragLr));
        _prot.setMintConfiguration(address(fragLr), IPatchworkProtocol.MintConfig(1000000000, true));
        // Scope owner cannot set fee overrides for anyone
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _scopeOwner));
        _prot.proposeScopeFeeOverride(_scopeName, IPatchworkProtocol.FeeConfigOverride(100, 100, 100, true)); // 1%

        IPatchworkProtocol.FeeConfigOverride memory protFee = _prot.getScopeFeeOverride(_scopeName);
        assertEq(false, protFee.active);
        assertEq(0, protFee.mintBp);
        assertEq(0, protFee.assignBp);
        assertEq(0, protFee.patchBp);

        vm.stopPrank();

        vm.prank(_patchworkOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NoProposedFeeSet.selector));
        _prot.commitScopeFeeOverride(_scopeName);

        vm.prank(_patchworkOwner);
        _prot.proposeScopeFeeOverride(_scopeName, IPatchworkProtocol.FeeConfigOverride(100, 100, 100, true)); // 1%
        protFee = _prot.getScopeFeeOverride(_scopeName);
        assertEq(false, protFee.active);
        assertEq(0, protFee.mintBp);
        assertEq(0, protFee.assignBp);
        assertEq(0, protFee.patchBp);

        vm.prank(_patchworkOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TimelockNotElapsed.selector));
        _prot.commitScopeFeeOverride(_scopeName);
        skip(2000000);
        vm.prank(_scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _scopeOwner));
        _prot.commitScopeFeeOverride(_scopeName);
        vm.prank(_patchworkOwner);
        _prot.commitScopeFeeOverride(_scopeName);
        vm.prank(_patchworkOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NoProposedFeeSet.selector));
        _prot.commitScopeFeeOverride(_scopeName);

        vm.prank(_patchworkOwner);
        _prot.addProtocolBanker(_user2Address);
        vm.prank(_user2Address);
        _prot.proposeScopeFeeOverride(_scopeName, IPatchworkProtocol.FeeConfigOverride(100, 100, 100, true)); // 1%
        protFee = _prot.getScopeFeeOverride(_scopeName);
        assertEq(true, protFee.active);
        assertEq(100, protFee.mintBp);
        assertEq(100, protFee.assignBp);
        assertEq(100, protFee.patchBp);

        vm.startPrank(_scopeOwner);
        _prot.mint{value: 1000000000}(_userAddress, address(fragLr), "");

        assertEq(990000000, _prot.balanceOf(_scopeName));
        assertEq(10000000, _prot.balanceOfProtocol());

        fragLr.registerReferenceAddress(address(fragLr));
        _prot.setAssignFee(address(fragLr), 1000000000);
        uint256 n1 = fragLr.mint(_userAddress, "");
        uint256 n2 = fragLr.mint(_userAddress, "");
        _prot.assign{value: _prot.getAssignFee(address(fragLr))}(address(fragLr), n2, address(fragLr), n1);

        assertEq(1980000000, _prot.balanceOf(_scopeName));
        assertEq(20000000, _prot.balanceOfProtocol());

        _prot.setPatchFee(address(t721), 1000000000);
        uint256 tId = tBase.mint(_userAddress);
        _prot.patch{value: _prot.getPatchFee(address(t721))}(_userAddress, address(tBase), tId, address(t721));

        assertEq(2970000000, _prot.balanceOf(_scopeName));
        assertEq(30000000, _prot.balanceOfProtocol());

        vm.stopPrank();
        vm.prank(_patchworkOwner);
        _prot.proposeScopeFeeOverride(_scopeName, IPatchworkProtocol.FeeConfigOverride(0, 0, 0, false)); // 1%
        skip(2000000);
        vm.prank(_patchworkOwner);
        _prot.commitScopeFeeOverride(_scopeName);
        protFee = _prot.getScopeFeeOverride(_scopeName);
        assertEq(false, protFee.active);
        assertEq(0, protFee.mintBp);
        assertEq(0, protFee.assignBp);
        assertEq(0, protFee.patchBp);
    }

    function testInvalidFeeValues() public {
        vm.startPrank(_patchworkOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InvalidFeeValue.selector));
        _prot.proposeProtocolFeeConfig(IPatchworkProtocol.FeeConfig(3001, 1000, 1000));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InvalidFeeValue.selector));
        _prot.proposeProtocolFeeConfig(IPatchworkProtocol.FeeConfig(1000, 3001, 1000));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InvalidFeeValue.selector));
        _prot.proposeProtocolFeeConfig(IPatchworkProtocol.FeeConfig(1000, 1000, 3001));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InvalidFeeValue.selector));
        _prot.proposeScopeFeeOverride(_scopeName, IPatchworkProtocol.FeeConfigOverride(3001, 0, 0, true));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InvalidFeeValue.selector));
        _prot.proposeScopeFeeOverride(_scopeName, IPatchworkProtocol.FeeConfigOverride(0, 3001, 0, true));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.InvalidFeeValue.selector));
        _prot.proposeScopeFeeOverride(_scopeName, IPatchworkProtocol.FeeConfigOverride(0, 0, 3001, true));
    }

    function testAssignBatchFees() public {
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
        uint256 nftAssignFee = _prot.getAssignFee(address(nft));
        assertEq(1, nftAssignFee);
        uint256 n1 = nft.mint(_userAddress, "");
        uint256[] memory fragmentIds = new uint256[](8);
        address[] memory fragmentAddresses = new address[](8);
        for (uint8 i = 0; i < 8; i++) {
            fragmentAddresses[i] = address(nft);
            fragmentIds[i] = nft.mint(_userAddress, "");
        }
        // No fee given should revert
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.assignBatch(fragmentAddresses, fragmentIds, address(nft), n1);
        // too little fee should revert
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.assignBatch{value: nftAssignFee}(fragmentAddresses, fragmentIds, address(nft), n1);
        // too much fee should revert
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectFeeAmount.selector));
        _prot.assignBatch{value: nftAssignFee * 9}(fragmentAddresses, fragmentIds, address(nft), n1);
        // correct fee should pass
        _prot.assignBatch{value: nftAssignFee * 8}(fragmentAddresses, fragmentIds, address(nft), n1);
    }
}