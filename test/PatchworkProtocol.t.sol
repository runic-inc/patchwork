// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";
import "./nfts/TestPatchLiteRefNFT.sol";
import "./nfts/TestFragmentLiteRefNFT.sol";
import "./nfts/TestBaseNFT.sol";
import "./nfts/TestPatchworkNFT.sol";
import "./nfts/TestMultiFragmentNFT.sol";
import "./nfts/TestPatchNFT.sol";

contract PatchworkProtocolTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    PatchworkProtocol _prot;
    TestBaseNFT _testBaseNFT;
    TestPatchworkNFT _testPatchworkNFT;
    TestPatchLiteRefNFT _testPatchLiteRefNFT;
    TestFragmentLiteRefNFT _testFragmentLiteRefNFT;
    TestMultiFragmentNFT _testMultiFragmentNFT;

    string _scopeName;
    address _defaultUser;
    address _patchworkOwner; 
    address _userAddress;
    address _user2Address;
    address _scopeOwner;

    function setUp() public {
        _defaultUser = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        _patchworkOwner = 0xF09CFF10D85E70D5AA94c85ebBEbD288756EFEd5;
        _userAddress = 0x10E4017cEd8648A9D5dAc21C82589C03C4835CCc;
        _user2Address = address(550001);
        _scopeOwner = 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5;

        vm.prank(_patchworkOwner);
        _prot = new PatchworkProtocol(_patchworkOwner, address(new PatchworkProtocolAssigner(_patchworkOwner)));
        _scopeName = "testscope";

        vm.prank(_userAddress);
        _testBaseNFT = new TestBaseNFT();

        vm.prank(_scopeOwner);
        _testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(_prot));
        vm.prank(_scopeOwner);        
        _testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(address(_prot));
        vm.prank(_scopeOwner);
        _testPatchworkNFT = new TestPatchworkNFT(address(_prot));
        vm.prank(_scopeOwner);
        _testMultiFragmentNFT = new TestMultiFragmentNFT(address(_prot));
    }

    function testScopeOwnerOperator() public {
        vm.startPrank(_scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _scopeOwner));
        _prot.claimScope("");
        _prot.claimScope(_scopeName);
        assertEq(_prot.getScopeOwner(_scopeName), _scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeExists.selector, _scopeName));
        _prot.claimScope(_scopeName);
        vm.stopPrank();
        // Current user is not scope owner so can't transfer it
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.transferScopeOwnership(_scopeName, address(2));
        // Real owner can transfer it
        vm.prank(_scopeOwner);
        _prot.transferScopeOwnership(_scopeName, address(3));
        // _scopeOwner still owns it until it's accepted
        assertEq(_prot.getScopeOwner(_scopeName), _scopeOwner);
        assertEq(_prot.getScopeOwnerElect(_scopeName), address(3));
        // test changing the pending transfer elect
        vm.prank(_scopeOwner);
        _prot.transferScopeOwnership(_scopeName, address(2));
        assertEq(_prot.getScopeOwnerElect(_scopeName), address(2));
        // Non-owner may not cancel the transfer
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(10)));
        vm.prank(address(10));
        _prot.cancelScopeTransfer(_scopeName);
        // Real owner can cancel the transfer
        vm.prank(_scopeOwner);
        _prot.cancelScopeTransfer(_scopeName);
        assertEq(_prot.getScopeOwnerElect(_scopeName), address(0));
        // Now retry the transfer
        vm.prank(_scopeOwner);
        _prot.transferScopeOwnership(_scopeName, address(2));
        // User 10 is not elect and may not accept the transfer
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(10)));
        vm.prank(address(10));
        _prot.acceptScopeTransfer(_scopeName);
        // Finally real elect accepts scope transfer
        vm.prank(address(2));
        _prot.acceptScopeTransfer(_scopeName);
        assertEq(_prot.getScopeOwner(_scopeName), address(2));
        assertEq(_prot.getScopeOwnerElect(_scopeName), address(0));
        // Old owner may not transfer it
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _scopeOwner));
        vm.prank(_scopeOwner);
        _prot.transferScopeOwnership(_scopeName, address(2));
        // New owner may transfer it back to old owner
        vm.prank(address(2));
        _prot.transferScopeOwnership(_scopeName, _scopeOwner);
        vm.prank(_scopeOwner);
        _prot.acceptScopeTransfer(_scopeName);
        assertEq(_prot.getScopeOwner(_scopeName), _scopeOwner);
        // Non-owner may not add operator
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(2)));
        vm.prank(address(2));
        _prot.addOperator(_scopeName, address(2));
        // Real owner may add operator
        vm.prank(_scopeOwner);
        _prot.addOperator(_scopeName, address(2));
        // Non-owner may not remove operator
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(2)));
        vm.prank(address(2));
        _prot.removeOperator(_scopeName, address(2));
        // Real owner may remove operator
        vm.prank(_scopeOwner);
        _prot.removeOperator(_scopeName, address(2));
        // Non-owner may not set scope rules
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(2)));
        vm.prank(address(2));
        _prot.setScopeRules(_scopeName, true, true, true);
    }

    function testCreatePatchNFTNoVerification() public {
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        uint256 tokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        assertEq(tokenId, 0);
    }

    function testCreatePatchNFTUnverified() public {
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(_testPatchLiteRefNFT)));
        _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
    }

    function testCreatePatchNFTVerified() public {
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.addWhitelist(_scopeName, address(_testPatchLiteRefNFT));
        vm.startPrank(_scopeOwner);
        _prot.addWhitelist(_scopeName, address(_testPatchLiteRefNFT));
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        uint256 tokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        assertEq(tokenId, 0);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.removeWhitelist(_scopeName, address(_testPatchLiteRefNFT));
        vm.startPrank(_scopeOwner);
        _prot.removeWhitelist(_scopeName, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(_testPatchLiteRefNFT)));
        tokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId + 1, address(_testPatchLiteRefNFT));
    }

    function testUserPermissions() public {
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        _prot.addWhitelist(_scopeName, address(_testPatchLiteRefNFT));
        _prot.addWhitelist(_scopeName, address(_testFragmentLiteRefNFT));
        uint256 fragmentTokenId = _testFragmentLiteRefNFT.mint(_userAddress, "");
        assertEq(_testFragmentLiteRefNFT.ownerOf(fragmentTokenId), _userAddress);
        //Register artifactNFT to _testPatchLiteRefNFT
        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        vm.stopPrank();
        vm.startPrank(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        vm.stopPrank();
        vm.prank(_scopeOwner);
        _prot.setScopeRules(_scopeName, true, false, true);
        vm.startPrank(_userAddress);
        patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.prank(_scopeOwner);
        _prot.setScopeRules(_scopeName, true, true, true);
        vm.prank(_userAddress);
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        // expect revert
        vm.prank(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TransferBlockedByAssignment.selector, _testFragmentLiteRefNFT, fragmentTokenId));
        _testFragmentLiteRefNFT.transferFrom(_userAddress, address(5), fragmentTokenId);
    }

    function testAssignNFT() public {
        vm.expectRevert(); // not assignable
        _prot.assign(address(1), 1, address(1), 1);

        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, _scopeName));
        _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.AlreadyPatched.selector, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT)));
        patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        
        uint256 fragmentTokenId = _testFragmentLiteRefNFT.mint(_userAddress, "");
        assertEq(_testFragmentLiteRefNFT.ownerOf(fragmentTokenId), _userAddress);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(_testFragmentLiteRefNFT)));
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        
        //Register artifactNFT to _testPatchLiteRefNFT
        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.SelfAssignmentNotAllowed.selector, address(_testFragmentLiteRefNFT), fragmentTokenId));
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testFragmentLiteRefNFT), fragmentTokenId);

        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        // cover called from non-owner/op with no allowUserAssign
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId, 0);
        
        vm.startPrank(_scopeOwner);
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId, 0);
        (address addr, uint256 tokenId) = _testFragmentLiteRefNFT.getAssignedTo(fragmentTokenId);
        assertEq(addr, address(_testPatchLiteRefNFT));
        assertEq(tokenId, patchTokenId);
        assertEq(_testFragmentLiteRefNFT.ownerOf(fragmentTokenId), _userAddress);

        _testFragmentLiteRefNFT.setTestLockOverride(true);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyAssigned.selector, address(_testFragmentLiteRefNFT), fragmentTokenId));
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        _testFragmentLiteRefNFT.setTestLockOverride(false);
        vm.stopPrank();
        
        vm.prank(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TransferNotAllowed.selector, address(_testPatchLiteRefNFT), patchTokenId));
        _testPatchLiteRefNFT.transferFrom(_userAddress, _user2Address, patchTokenId);
    }

    function testScopeDoesNotExist() public {
        vm.startPrank(_scopeOwner);
 
        uint256 fragmentTokenId1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragmentTokenId2 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 multi1 = _testMultiFragmentNFT.mint(_userAddress, "");
        //Register _testPatchLiteRefNFT to _testPatchLiteRefNFT
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testMultiFragmentNFT));
        // Single
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, _scopeName));
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId1, address(_testFragmentLiteRefNFT), fragmentTokenId2);
        // Multi
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, _scopeName));
        _prot.assign(address(_testMultiFragmentNFT), multi1, address(_testFragmentLiteRefNFT), fragmentTokenId2);
        address[] memory fragmentAddresses = new address[](1);
        uint256[] memory fragments = new uint256[](1);
        fragmentAddresses[0] = address(_testFragmentLiteRefNFT);
        fragments[0] = fragmentTokenId1;
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, _scopeName));
        _prot.assignBatch(fragmentAddresses, fragments, address(_testFragmentLiteRefNFT), fragmentTokenId2);
        // Claim scope to get assignments done to test unassign
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId1, address(_testFragmentLiteRefNFT), fragmentTokenId2);
        _prot.assign(address(_testMultiFragmentNFT), multi1, address(_testFragmentLiteRefNFT), fragmentTokenId2);
        // Memoization will prevent the scope change from taking effect.
        _testFragmentLiteRefNFT.setScopeName("foo");
        _testMultiFragmentNFT.setScopeName("foo");
        _prot.unassign(address(_testFragmentLiteRefNFT), fragmentTokenId1, address(_testFragmentLiteRefNFT), fragmentTokenId2);
        _prot.unassign(address(_testMultiFragmentNFT), multi1, address(_testFragmentLiteRefNFT), fragmentTokenId2, 0);
    }

    function testUnsupportedNFTUnassign() public {
        uint256 t1 = _testBaseNFT.mint(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedContract.selector));
        _prot.unassign(address(_testBaseNFT), t1, address(_testBaseNFT), t1);
    }

    function testScopeTransferCannotBeFrontrun() public {
        address maliciousActor = address(120938);
        // A malicious actor attempts to preconfigure and transfer a scope to 0 so an unsuspecting actor claims it but it already has operators preconfigured
        vm.startPrank(maliciousActor);
        _prot.claimScope("foo");
        _prot.addOperator("foo", address(4));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeTransferNotAllowed.selector, address(0)));
        _prot.transferScopeOwnership("foo", address(0));
    }

    function testUserAssignNFT() public {
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, true, true, true);
        _prot.addWhitelist(_scopeName, address(_testPatchLiteRefNFT));
        //Register artifactNFT to _testPatchLiteRefNFT
        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        vm.stopPrank();
        vm.startPrank(_userAddress);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
 
        uint256 fragmentTokenId = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 user2FragmentTokenId = _testFragmentLiteRefNFT.mint(_user2Address, "");
        assertEq(_testFragmentLiteRefNFT.ownerOf(fragmentTokenId), _userAddress);
 
        // Not whitelisted
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(_testFragmentLiteRefNFT)));
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.prank(_scopeOwner);
        _prot.addWhitelist(_scopeName, address(_testFragmentLiteRefNFT));

        // user 2 does not own either of these
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);

        // fragment and target have different owners
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.assign(address(_testFragmentLiteRefNFT), user2FragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);

        // fragment and target have different owners
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.startPrank(_userAddress);
        _prot.assign(address(_testFragmentLiteRefNFT), user2FragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);

        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
        (address addr, uint256 tokenId) = _testFragmentLiteRefNFT.getAssignedTo(fragmentTokenId);
        assertEq(addr, address(_testPatchLiteRefNFT));
        assertEq(tokenId, patchTokenId);
        assertEq(_testFragmentLiteRefNFT.ownerOf(fragmentTokenId), _userAddress);
        vm.stopPrank();
        // not owned by user 2
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragmentTokenId);
        vm.startPrank(_userAddress);
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragmentTokenId, 1);
        // not currently assigned
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentNotAssigned.selector, address(_testFragmentLiteRefNFT), fragmentTokenId));
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragmentTokenId);
    }

   function testDontAssignSomeoneElsesNFT() public {
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
 
        uint256 fragmentTokenId = _testFragmentLiteRefNFT.mint(_user2Address, "");
        assertEq(_testFragmentLiteRefNFT.ownerOf(fragmentTokenId), _user2Address);
        //Register artifactNFT to _testPatchLiteRefNFT
        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _scopeOwner));
        _prot.assign(address(_testFragmentLiteRefNFT), fragmentTokenId, address(_testPatchLiteRefNFT), patchTokenId);
    }

   function testUnassignNFT() public {
        vm.expectRevert(); // not unassignable
        _prot.unassignSingle(address(1), 1);

        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        uint256 fragment1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment2 = _testFragmentLiteRefNFT.mint(_userAddress, "");

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));

        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        //Register _testFragmentLiteRefNFT to _testFragmentLiteRefNFT to allow recursion
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));

        // Assign Id1 -> Id
        _prot.assign(address(_testFragmentLiteRefNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), fragment1);
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment2);
        vm.startPrank(_scopeOwner);
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment2);
        // Now Id1 -> Id, unassign Id1 from Id
        _prot.unassign(address(_testFragmentLiteRefNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId, 0);
        // Assign Id1 -> Id
        _prot.assign(address(_testFragmentLiteRefNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), fragment1);
        // Now Id2 -> Id1 -> Id, unassign Id1 from Id
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment1);
        // Assign Id1 -> Id
        _prot.assign(address(_testFragmentLiteRefNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.startPrank(_testBaseNFT.ownerOf(_testBaseNFTTokenId));
        // transfer ownership of underlying asset (_testBaseNFT)
        _testBaseNFT.transferFrom(_testBaseNFT.ownerOf(_testBaseNFTTokenId), address(7), _testBaseNFTTokenId);
        vm.stopPrank();
        vm.startPrank(_scopeOwner);

        _testFragmentLiteRefNFT.setGetLiteRefOverride(true, 0);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(_testFragmentLiteRefNFT)));
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment2);
        _testFragmentLiteRefNFT.setGetLiteRefOverride(false, 0);

        // Revert b/c this isn't the expected assignment given explicitly
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentNotAssignedToTarget.selector, address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), 15000));
        _prot.unassign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), 15000);

        // Now Id2 -> Id1 -> Id where Id belongs to 7, unassign Id2 from Id1 and check new ownership
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment2);
        assertEq(_testFragmentLiteRefNFT.ownerOf(fragment2),  address(7));

        _testFragmentLiteRefNFT.setGetAssignedToOverride(true, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.RefNotFound.selector, address(_testPatchLiteRefNFT), address(_testFragmentLiteRefNFT), fragment2));
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment2);
        _testFragmentLiteRefNFT.setGetAssignedToOverride(false, address(_testPatchLiteRefNFT));
        vm.stopPrank();

        // try to transfer a patch directly - it should be blocked because it is soulbound
        assertEq(address(7), _testPatchLiteRefNFT.ownerOf(patchTokenId)); // Report as soulbound
        vm.startPrank(_userAddress); // Prank from underlying owner address
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TransferNotAllowed.selector, address(_testPatchLiteRefNFT), patchTokenId));
        _testPatchLiteRefNFT.transferFrom(_userAddress, address(7), patchTokenId);
        vm.stopPrank();
    }

   function testUnassignMultiNFT() public {
        vm.expectRevert(); // not unassignable
        _prot.unassignMulti(address(1), 1, address(1), 1);

        vm.expectRevert(); // not unassignable
        _prot.unassignMulti(address(1), 1, address(1), 1, 0);
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        uint256 fragment1 = _testMultiFragmentNFT.mint(_userAddress, "");

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));

        _testPatchLiteRefNFT.registerReferenceAddress(address(_testMultiFragmentNFT));
        _prot.assign(address(_testMultiFragmentNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        _prot.unassign(address(_testMultiFragmentNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentNotAssignedToTarget.selector, address(_testMultiFragmentNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId));
        _prot.unassign(address(_testMultiFragmentNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
   }

    function testBatchAssignNFT() public {
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        address[] memory fragmentAddresses = new address[](8);
        uint256[] memory fragments = new uint256[](8);

        for (uint8 i = 0; i < 8; i++) {
            fragmentAddresses[i] = address(_testFragmentLiteRefNFT);
            fragments[i] = _testFragmentLiteRefNFT.mint(_userAddress, "");
        }

        // Fragment must be registered
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(_testFragmentLiteRefNFT)));
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        uint8 refId = _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));

        vm.stopPrank();
        // User may not assign without userAssign enabled
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);

        vm.prank(_scopeOwner);
        _prot.setScopeRules(_scopeName, false, false, true);
        vm.startPrank(_scopeOwner);
        // Whitelist enabled requires whitelisted (both patch and fragment)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(_testPatchLiteRefNFT)));
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        
        _prot.addWhitelist(_scopeName, address(_testPatchLiteRefNFT));
        // Whitelist enabled requires whitelisted (now just fragment)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, _scopeName, address(_testFragmentLiteRefNFT)));
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        
        _prot.addWhitelist(_scopeName, address(_testFragmentLiteRefNFT));

        // Inputs do not match length
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.BadInputLengths.selector));
        _prot.assignBatch(new address[](1), fragments, address(_testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.prank(_userAddress);
        _testPatchLiteRefNFT.setFrozen(patchTokenId, true);
        // It's frozen (patch)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(_testPatchLiteRefNFT), patchTokenId));
        vm.prank(_scopeOwner);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        vm.prank(_userAddress);
        _testPatchLiteRefNFT.setFrozen(patchTokenId, false);

        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setFrozen(fragments[0], true);
        // It's frozen (fragment)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(_testFragmentLiteRefNFT), fragments[0]));
        vm.prank(_scopeOwner);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setFrozen(fragments[0], false);

        vm.prank(_scopeOwner);
        _testPatchLiteRefNFT.redactReferenceAddress(refId);
        // Fragment was redacted
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentRedacted.selector, address(_testFragmentLiteRefNFT)));
        vm.prank(_scopeOwner);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        vm.prank(_scopeOwner);
        _testPatchLiteRefNFT.unredactReferenceAddress(refId);

        address[] memory selfAddr = new address[](1);
        uint256[] memory selfFrag = new uint256[](1);
        selfAddr[0] = address(_testPatchLiteRefNFT);
        selfFrag[0] = patchTokenId;
        // Self-assignment
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.SelfAssignmentNotAllowed.selector, selfAddr[0], selfFrag[0]));
        vm.prank(_scopeOwner);     
        _prot.assignBatch(selfAddr, selfFrag, address(_testPatchLiteRefNFT), patchTokenId);

        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setLocked(fragments[0], true);
        // Fragment is locked
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Locked.selector, address(_testFragmentLiteRefNFT), fragments[0]));
        vm.prank(_scopeOwner);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setLocked(fragments[0], false);

        // test assigning fragments for another user
        address[] memory otherUserAddr = new address[](1);
        uint256[] memory otherUserFrag = new uint256[](1);
        otherUserAddr[0] = address(_testFragmentLiteRefNFT);
        otherUserFrag[0] = _testFragmentLiteRefNFT.mint(_user2Address, "");
        // Target and fragment not same owner
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _scopeOwner));
        vm.prank(_scopeOwner);     
        _prot.assignBatch(otherUserAddr, otherUserFrag, address(_testPatchLiteRefNFT), patchTokenId);
    
        // finally a positive test case
        vm.prank(_scopeOwner);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId, 0);

        for (uint8 i = 0; i < 8; i++) {
            (address addr, uint256 tokenId) = _testFragmentLiteRefNFT.getAssignedTo(fragments[i]);
            assertEq(addr, address(_testPatchLiteRefNFT));
            assertEq(tokenId, patchTokenId);
            assertEq(_testFragmentLiteRefNFT.ownerOf(fragments[i]), _userAddress);
            _testFragmentLiteRefNFT.setTestLockOverride(true); // setup for next test part
        }

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyAssigned.selector, fragmentAddresses[0], fragments[0]));
        vm.prank(_scopeOwner);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
    }

    function testBatchUserPatchAssignNFT() public {
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, true, true, false);
        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        vm.stopPrank();

        vm.startPrank(_userAddress);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        address[] memory fragmentAddresses = new address[](8);
        uint256[] memory fragments = new uint256[](8);
        uint256[] memory user2Fragments = new uint256[](8);

        for (uint8 i = 0; i < 8; i++) {
            fragmentAddresses[i] = address(_testFragmentLiteRefNFT);
            fragments[i] = _testFragmentLiteRefNFT.mint(_userAddress, "");
            user2Fragments[i] = _testFragmentLiteRefNFT.mint(_user2Address, "");
        }
 
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);
        
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _prot.assignBatch(fragmentAddresses, user2Fragments, address(_testPatchLiteRefNFT), patchTokenId);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.assignBatch(fragmentAddresses, user2Fragments, address(_testPatchLiteRefNFT), patchTokenId);

        // test assigning fragments for another user
        address[] memory otherUserAddr = new address[](1);
        uint256[] memory otherUserFrag = new uint256[](1);
        otherUserAddr[0] = address(_testFragmentLiteRefNFT);
        otherUserFrag[0] = _testFragmentLiteRefNFT.mint(_user2Address, "");
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress);
        _prot.assignBatch(otherUserAddr, otherUserFrag, address(_testPatchLiteRefNFT), patchTokenId);

        // finally a positive test case
        vm.startPrank(_userAddress);
        _prot.assignBatch(fragmentAddresses, fragments, address(_testPatchLiteRefNFT), patchTokenId);

        for (uint8 i = 0; i < 8; i++) {
            (address addr, uint256 tokenId) = _testFragmentLiteRefNFT.getAssignedTo(fragments[i]);
            assertEq(addr, address(_testPatchLiteRefNFT));
            assertEq(tokenId, patchTokenId);
            assertEq(_testFragmentLiteRefNFT.ownerOf(fragments[i]), _userAddress);
        }
        vm.stopPrank();
    }

    function testTransferLogs() public {
        uint256 fragment1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment2 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment3 = _testFragmentLiteRefNFT.mint(_userAddress, "");

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);

        //Register _testFragmentLiteRefNFT to _testFragmentLiteRefNFT to allow recursion
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));

        // Assign Id2 -> Id1
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), fragment1);
        // Assign Id3 -> Id2
        _prot.assign(address(_testFragmentLiteRefNFT), fragment3, address(_testFragmentLiteRefNFT), fragment2);
        vm.stopPrank();
        vm.expectEmit(true, true, true, true, address(_testFragmentLiteRefNFT));
        emit Transfer(_userAddress, _user2Address, fragment2);
        vm.expectEmit(true, true, true, true, address(_testFragmentLiteRefNFT));
        emit Transfer(_userAddress, _user2Address, fragment3);
        vm.expectEmit(true, true, true, true, address(_testFragmentLiteRefNFT));
        emit Transfer(_userAddress, _user2Address, fragment1);
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.transferFrom(_userAddress, _user2Address, fragment1);
        assertEq(_user2Address, _testFragmentLiteRefNFT.ownerOf(fragment1));
        assertEq(_user2Address, _testFragmentLiteRefNFT.ownerOf(fragment2));
        assertEq(_user2Address, _testFragmentLiteRefNFT.ownerOf(fragment3));
    }

    function testUpdateOwnership() public {
        uint256 fragment1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment2 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment3 = _testFragmentLiteRefNFT.mint(_userAddress, "");

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);

        //Register _testFragmentLiteRefNFT to _testFragmentLiteRefNFT to allow recursion
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));

        // Assign Id2 -> Id1
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), fragment1);
        // Assign Id3 -> Id2
        _prot.assign(address(_testFragmentLiteRefNFT), fragment3, address(_testFragmentLiteRefNFT), fragment2);
        vm.stopPrank();
        vm.prank(_userAddress);
        // This won't actually transfer fragments 2 and 3
        _testFragmentLiteRefNFT.transferFrom(_userAddress, _user2Address, fragment1);
        assertEq(_user2Address, _testFragmentLiteRefNFT.unassignedOwnerOf(fragment1));
        assertEq(_userAddress, _testFragmentLiteRefNFT.unassignedOwnerOf(fragment2));
        assertEq(_userAddress, _testFragmentLiteRefNFT.unassignedOwnerOf(fragment3));
        _prot.updateOwnershipTree(address(_testFragmentLiteRefNFT), fragment1);
        assertEq(_user2Address, _testFragmentLiteRefNFT.unassignedOwnerOf(fragment1));
        assertEq(_user2Address, _testFragmentLiteRefNFT.unassignedOwnerOf(fragment2));
        assertEq(_user2Address, _testFragmentLiteRefNFT.unassignedOwnerOf(fragment3));

        // test with patch
        TestPatchNFT patch = new TestPatchNFT(address(_prot));
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(patch));
        vm.prank(_userAddress);
        _testBaseNFT.transferFrom(_userAddress, _user2Address, _testBaseNFTTokenId);
        assertEq(_user2Address, patch.ownerOf(patchTokenId));
        assertEq(_userAddress, patch.ownerOfPatch(patchTokenId));
        _prot.updateOwnershipTree(address(patch), patchTokenId);
        assertEq(_user2Address, patch.ownerOfPatch(patchTokenId));
    }

    function testLocks() public {
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        uint256 fragment1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment2 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 n = _testPatchworkNFT.mint(_userAddress, "");
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));

        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        //Register _testFragmentLiteRefNFT to _testFragmentLiteRefNFT to allow recursion
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        vm.stopPrank();

        // cannot lock a patch
        assertEq(false, _testPatchLiteRefNFT.locked(patchTokenId));
        vm.expectRevert();
        vm.prank(_userAddress);
        _testPatchLiteRefNFT.setLocked(patchTokenId, true);

        // can lock an unassigned fragment
        assertEq(false, _testFragmentLiteRefNFT.locked(fragment1));
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setLocked(fragment1, true);
        assertEq(true, _testFragmentLiteRefNFT.locked(fragment1));
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setLocked(fragment1, false);

        // only owner may lock
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _testFragmentLiteRefNFT.setLocked(fragment1, true);
        // only owner may lock
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        _testPatchworkNFT.setLocked(n, true);

        // an assigned fragment is locked implicitly
        assertEq(false, _testFragmentLiteRefNFT.locked(fragment1));
        vm.prank(_scopeOwner);
        // Assign Id1 -> Id
        _prot.assign(address(_testFragmentLiteRefNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        assertEq(true, _testFragmentLiteRefNFT.locked(fragment1));

        // cannot lock an assigned fragment
        vm.expectRevert();
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setLocked(fragment1, true);

        // cannot assign a locked fragment
        vm.startPrank(_userAddress);
        _testFragmentLiteRefNFT.setLocked(fragment2, true);
        vm.expectRevert();
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testPatchLiteRefNFT), patchTokenId);

        // cannot transfer a locked fragment
        vm.expectRevert();
        _testFragmentLiteRefNFT.transferFrom(_userAddress, address(100), fragment2);
        _testFragmentLiteRefNFT.setLocked(fragment2, false);
        _testFragmentLiteRefNFT.transferFrom(_userAddress, address(100), fragment2);
        assertEq(address(100), _testFragmentLiteRefNFT.ownerOf(fragment2));
        vm.stopPrank();
    }

    function testFreezes() public {
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        uint256 fragment1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment2 = _testFragmentLiteRefNFT.mint(_userAddress, "");

        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));

        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        //Register _testFragmentLiteRefNFT to _testFragmentLiteRefNFT to allow recursion
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        vm.stopPrank();

        // Freeze the patch, shouldn't allow assignment of a child
        vm.prank(_userAddress);
        _testPatchLiteRefNFT.setFrozen(patchTokenId, true);
        assertEq(0, _testPatchLiteRefNFT.getFreezeNonce(patchTokenId));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(_testPatchLiteRefNFT), patchTokenId));
        vm.prank(_scopeOwner);
        // Assign Id1 -> Id
        _prot.assign(address(_testFragmentLiteRefNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        vm.prank(_userAddress);
        _testPatchLiteRefNFT.setFrozen(patchTokenId, false);
        vm.startPrank(_scopeOwner);
        assertEq(1, _testPatchLiteRefNFT.getFreezeNonce(patchTokenId));
        // Assign Id1 -> Id
        _prot.assign(address(_testFragmentLiteRefNFT), fragment1, address(_testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), fragment1);

        // Lock the patch, shouldn't allow unassignment of any child
        vm.stopPrank();
        vm.prank(_userAddress);
        _testPatchLiteRefNFT.setFrozen(patchTokenId, true);

        // It will return that the fragment is frozen even though the patch is the root cause, because all assigned to the patch inherit the freeze
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(_testFragmentLiteRefNFT), fragment2));
        vm.prank(_scopeOwner);
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment2);
        vm.prank(_userAddress);
        _testPatchLiteRefNFT.setFrozen(patchTokenId, false);
        assertEq(2, _testPatchLiteRefNFT.getFreezeNonce(patchTokenId));
        vm.startPrank(_scopeOwner);       
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment2, 0);
        vm.stopPrank();
        vm.startPrank(_scopeOwner);
        // Unassign Id1 from patch
        _prot.unassignSingle(address(_testFragmentLiteRefNFT), fragment1);
        vm.stopPrank();

        // Lock the fragment, shouldn't allow assignment to anything
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setFrozen(fragment1, true);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(_testFragmentLiteRefNFT), fragment1));
        vm.prank(_scopeOwner);
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), fragment1);
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.setFrozen(fragment2, true);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(_testFragmentLiteRefNFT), fragment1));
        vm.prank(_scopeOwner);
        _prot.assign(address(_testFragmentLiteRefNFT), fragment2, address(_testFragmentLiteRefNFT), fragment1);
        vm.startPrank(_userAddress);
        _testFragmentLiteRefNFT.setFrozen(fragment2, false);

        // test transfers with lock nonce mismatch
        // first unassign the fragment b/c you can't unassign a locked one
        uint256 nonce = _testFragmentLiteRefNFT.getFreezeNonce(fragment2);
        _testFragmentLiteRefNFT.setFrozen(fragment2, true);
        _testFragmentLiteRefNFT.setFrozen(fragment2, false); // nonce +1
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, address(_testFragmentLiteRefNFT), fragment2));
        _testFragmentLiteRefNFT.transferFromWithFreezeNonce(_userAddress, _user2Address, fragment2, nonce+1);
        assertEq(false, _testFragmentLiteRefNFT.frozen(fragment2));
        _testFragmentLiteRefNFT.setFrozen(fragment2, true);
        assertEq(true, _testFragmentLiteRefNFT.frozen(fragment2));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, address(_testFragmentLiteRefNFT), fragment2, nonce));
        _testFragmentLiteRefNFT.transferFromWithFreezeNonce(_userAddress, _user2Address, fragment2, nonce);
        // now success
        _testFragmentLiteRefNFT.transferFromWithFreezeNonce(_userAddress, _user2Address, fragment2, nonce+1);
        assertEq(_user2Address, _testFragmentLiteRefNFT.ownerOf(fragment2));
    }

    function testSpoofedTransfer1() public {
        vm.startPrank(_scopeOwner);
        // create a patchworkliteref but manually put in an entry that isn't assigned to it (spoof ownership)
        uint256 fragment1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 fragment2 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        (uint64 ref, ) = _testFragmentLiteRefNFT.getLiteReference(address(_testFragmentLiteRefNFT), fragment2);
        _testFragmentLiteRefNFT.addReference(fragment1, ref);
        // Should revert with data integrity error
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.DataIntegrityError.selector, address(_testFragmentLiteRefNFT), fragment1, address(0), 0));
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.transferFrom(_userAddress, _user2Address, fragment1);
    }

    function testSpoofedTransfer2() public {
        vm.startPrank(_scopeOwner);
        // create a patchworkliteref but manually put in an entry that isn't assigned to it (spoof ownership)
        uint256 fragment1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        _testFragmentLiteRefNFT.registerReferenceAddress(address(_testBaseNFT));
        (uint64 ref, ) = _testFragmentLiteRefNFT.getLiteReference(address(_testBaseNFT), _testBaseNFTTokenId);
        _testFragmentLiteRefNFT.addReference(fragment1, ref);
        // Should revert with data integrity error
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotPatchworkAssignable.selector, address(_testBaseNFT)));
        vm.prank(_userAddress);
        _testFragmentLiteRefNFT.transferFrom(_userAddress, _user2Address, fragment1);
    }

    function testLiteRefCollision() public {
        TestFragmentLiteRefNFT testFrag2 = new TestFragmentLiteRefNFT(address(_prot));
        vm.startPrank(_scopeOwner);
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        _testPatchLiteRefNFT.registerReferenceAddress(address(_testFragmentLiteRefNFT));
        _testFragmentLiteRefNFT.registerReferenceAddress(address(testFrag2));
        uint256 frag1 = _testFragmentLiteRefNFT.mint(_userAddress, "");
        uint256 frag2 = testFrag2.mint(_userAddress, "");
        uint256 _testBaseNFTTokenId = _testBaseNFT.mint(_userAddress);
        uint256 patchTokenId = _prot.patch(_userAddress, address(_testBaseNFT), _testBaseNFTTokenId, address(_testPatchLiteRefNFT));
        _prot.assign(address(_testFragmentLiteRefNFT), frag1, address(_testPatchLiteRefNFT), patchTokenId);
        // The second assign succeeding combined with the assertion that they are equal ref values means there is no collision in the scope.
        _prot.assign(address(testFrag2), frag2, address(_testFragmentLiteRefNFT), frag1);
        // LiteRef IDs should match because it is idx1 tokenID 0 for both (0x1. 0x0)
        (uint64 lr1,) = _testPatchLiteRefNFT.getLiteReference(address(_testFragmentLiteRefNFT), frag1);
        (uint64 lr2,) = _testFragmentLiteRefNFT.getLiteReference(address(testFrag2), frag2);
        assertEq(lr1, lr2);
    }

     function testBurn() public {
        // *burned* can only be called from the patch burning it
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.patchBurned(address(1), 1, address(2));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.patchBurned1155(address(1), 1, address(3), address(2));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _prot.patchBurnedAccount(address(1), address(2));
     }
}