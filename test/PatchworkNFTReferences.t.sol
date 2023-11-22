// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "./nfts/TestPatchLiteRefNFT.sol";
import "./nfts/TestFragmentLiteRefNFT.sol";
import "./nfts/TestBaseNFT.sol";

contract PatchworkNFTCombinedTest is Test {
    PatchworkProtocol _prot;
    TestBaseNFT _testBaseNFT;
    TestPatchLiteRefNFT _testPatchLiteRefNFT;
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
        _prot = new PatchworkProtocol();
        _scopeName = "testscope";
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);

        _testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(_prot)); 
        _testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(address(_prot));

        vm.stopPrank();
        vm.prank(_userAddress);
        _testBaseNFT = new TestBaseNFT();
    }

    function testReferenceAddresses() public {
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        uint8 refIdx = _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        (uint64 ref, bool redacted) = _testPatchLiteRefNFT.getLiteReference(address(_testFragmentLiteRefNFT), 1);
        assertEq(0, ref);
        vm.prank(_scopeOwner);
        refIdx = _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        (uint8 _id, bool _redacted) = _testPatchLiteRefNFT.getReferenceId(address(_testFragmentLiteRefNFT));
        assertEq(refIdx, _id);
        assertFalse(_redacted);
        (address _addr, bool _redacted2) = _testPatchLiteRefNFT.getReferenceAddress(refIdx);
        assertEq(address(_testFragmentLiteRefNFT), _addr);
        assertFalse(_redacted2);
        (ref, redacted) = _testPatchLiteRefNFT.getLiteReference(address(_testFragmentLiteRefNFT), 1);
        (address refAddr, uint256 tokenId) = _testPatchLiteRefNFT.getReferenceAddressAndTokenId(ref);
        assertEq(address(_testFragmentLiteRefNFT), refAddr);
        assertEq(1, tokenId);

        // test assign perms
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        uint256 fragmentTokenId = _testFragmentLiteRefNFT.mint(_userAddress, "");
        assertEq(_userAddress, _testFragmentLiteRefNFT.ownerOf(fragmentTokenId)); // TODO why doesn't this cover the branch != address(0)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        uint256 patchTokenId = _prot.createPatch(_userAddress, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress); // must have user patch enabled
        patchTokenId = _prot.createPatch(_userAddress, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        vm.prank(_scopeOwner);
        patchTokenId = _prot.createPatch(_userAddress, address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress); // can't call directly
        _testFragmentLiteRefNFT.assign(fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress); // must be owner/manager
        _prot.assignNFT(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);

        vm.prank(_scopeOwner);
        _prot.assignNFT(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        assertEq(_userAddress, _testFragmentLiteRefNFT.ownerOf(fragmentTokenId)); // TODO why doesn't this cover the branch != address(0)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyAssigned.selector, address(_testFragmentLiteRefNFT), fragmentTokenId));
        vm.prank(_scopeOwner); // not normal to call directly but need to test the correct error
        _testFragmentLiteRefNFT.assign(fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress); // can't call directly
        _testFragmentLiteRefNFT.unassign(fragmentTokenId);

        uint256 newFrag = _testFragmentLiteRefNFT.mint(_userAddress, "");
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchLiteRefNFT.redactReferenceAddress(refIdx);
        vm.prank(_scopeOwner);
        _testPatchLiteRefNFT.redactReferenceAddress(refIdx);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentRedacted.selector, address(_testFragmentLiteRefNFT)));
        vm.prank(_scopeOwner);
        _prot.assignNFT(address(_testFragmentLiteRefNFT), newFrag, address(_testPatchLiteRefNFT), patchTokenId);
        
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchLiteRefNFT.unredactReferenceAddress(refIdx);
        vm.prank(_scopeOwner);
        _testPatchLiteRefNFT.unredactReferenceAddress(refIdx);
        vm.prank(_scopeOwner);
        _prot.assignNFT(address(_testFragmentLiteRefNFT), newFrag, address(_testPatchLiteRefNFT), patchTokenId);
    }

    function testReferenceAddressErrors() public {
        vm.startPrank(_scopeOwner);
        uint8 refIdx = _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        assertEq(1, refIdx);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyRegistered.selector, address(_testFragmentLiteRefNFT)));
        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        // Fill ID 2 to 254 then test overflow
        for (uint8 i = 2; i < 255; i++) {
            refIdx = _testPatchLiteRefNFT.registerReferenceAddress(address(bytes20(uint160(i))));
        }
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.OutOfIDs.selector));
        refIdx = _testPatchLiteRefNFT.registerReferenceAddress(address(256));
    }
}