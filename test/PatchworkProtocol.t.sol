// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/sampleNFTs/TestPatchLiteRefNFT.sol";
import "../src/sampleNFTs/TestFragmentLiteRefNFT.sol";
import "../src/sampleNFTs/TestBaseNFT.sol";
import "../src/sampleNFTs/TestPatchworkNFT.sol";
import "../src/sampleNFTs/TestMultiFragmentNFT.sol";

contract PatchworkProtocolTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    PatchworkProtocol prot;
    TestBaseNFT testBaseNFT;
    TestPatchworkNFT testPatchworkNFT;
    TestPatchLiteRefNFT testPatchLiteRefNFT;
    TestFragmentLiteRefNFT testFragmentLiteRefNFT;
    TestMultiFragmentNFT testMultiFragmentNFT;

    string scopeName;
    address defaultUser;
    address patchworkOwner; 
    address userAddress;
    address user2Address;
    address scopeOwner;

    function setUp() public {
        defaultUser = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        patchworkOwner = 0xF09CFF10D85E70D5AA94c85ebBEbD288756EFEd5;
        userAddress = 0x10E4017cEd8648A9D5dAc21C82589C03C4835CCc;
        user2Address = address(550001);
        scopeOwner = 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5;

        vm.prank(patchworkOwner);
        prot = new PatchworkProtocol();
        scopeName = "testscope";

        vm.prank(userAddress);
        testBaseNFT = new TestBaseNFT();

        vm.prank(scopeOwner);
        testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(prot));
        vm.prank(scopeOwner);        
        testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(address(prot));
        vm.prank(scopeOwner);
        testPatchworkNFT = new TestPatchworkNFT(address(prot));
        vm.prank(scopeOwner);
        testMultiFragmentNFT = new TestMultiFragmentNFT(address(prot));
    }

    function testScopeOwnerOperator() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        assertEq(prot.getScopeOwner(scopeName), scopeOwner);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeExists.selector, scopeName));
        prot.claimScope(scopeName);
        vm.stopPrank();
        // Current user is not scope owner so can't transfer it
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, defaultUser));
        prot.transferScopeOwnership(scopeName, address(2));
        // Real owner can transfer it
        vm.prank(scopeOwner);
        prot.transferScopeOwnership(scopeName, address(3));
        // scopeOwner still owns it until it's accepted
        assertEq(prot.getScopeOwner(scopeName), scopeOwner);
        assertEq(prot.getScopeOwnerElect(scopeName), address(3));
        // test changing the pending transfer elect
        vm.prank(scopeOwner);
        prot.transferScopeOwnership(scopeName, address(2));
        assertEq(prot.getScopeOwnerElect(scopeName), address(2));
        // Non-owner may not cancel the transfer
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(10)));
        vm.prank(address(10));
        prot.cancelScopeTransfer(scopeName);
        // Real owner can cancel the transfer
        vm.prank(scopeOwner);
        prot.cancelScopeTransfer(scopeName);
        assertEq(prot.getScopeOwnerElect(scopeName), address(0));
        // Now retry the transfer
        vm.prank(scopeOwner);
        prot.transferScopeOwnership(scopeName, address(2));
        // User 10 is not elect and may not accept the transfer
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(10)));
        vm.prank(address(10));
        prot.acceptScopeTransfer(scopeName);
        // Finally real elect accepts scope transfer
        vm.prank(address(2));
        prot.acceptScopeTransfer(scopeName);
        assertEq(prot.getScopeOwner(scopeName), address(2));
        assertEq(prot.getScopeOwnerElect(scopeName), address(0));
        // Old owner may not transfer it
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, scopeOwner));
        vm.prank(scopeOwner);
        prot.transferScopeOwnership(scopeName, address(2));
        // New owner may transfer it back to old owner
        vm.prank(address(2));
        prot.transferScopeOwnership(scopeName, scopeOwner);
        vm.prank(scopeOwner);
        prot.acceptScopeTransfer(scopeName);
        assertEq(prot.getScopeOwner(scopeName), scopeOwner);
        // Non-owner may not add operator
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(2)));
        vm.prank(address(2));
        prot.addOperator(scopeName, address(2));
        // Real owner may add operator
        vm.prank(scopeOwner);
        prot.addOperator(scopeName, address(2));
        // Non-owner may not remove operator
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(2)));
        vm.prank(address(2));
        prot.removeOperator(scopeName, address(2));
        // Real owner may remove operator
        vm.prank(scopeOwner);
        prot.removeOperator(scopeName, address(2));
        // Non-owner may not set scope rules
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, address(2)));
        vm.prank(address(2));
        prot.setScopeRules(scopeName, true, true, true);
    }

    function testCreatePatchNFTNoVerification() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 tokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        assertEq(tokenId, 0);
    }

    function testCreatePatchNFTUnverified() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, scopeName, address(testPatchLiteRefNFT)));
        prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
    }

    function testCreatePatchNFTVerified() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress);
        prot.addWhitelist(scopeName, address(testPatchLiteRefNFT));
        vm.startPrank(scopeOwner);
        prot.addWhitelist(scopeName, address(testPatchLiteRefNFT));
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 tokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        assertEq(tokenId, 0);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress);
        prot.removeWhitelist(scopeName, address(testPatchLiteRefNFT));
        vm.startPrank(scopeOwner);
        prot.removeWhitelist(scopeName, address(testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, scopeName, address(testPatchLiteRefNFT)));
        tokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId + 1, address(testPatchLiteRefNFT));
    }

    function testUserPermissions() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        prot.addWhitelist(scopeName, address(testPatchLiteRefNFT));
        prot.addWhitelist(scopeName, address(testFragmentLiteRefNFT));
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(userAddress);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);
        //Register artifactNFT to testPatchLiteRefNFT
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.stopPrank();
        vm.startPrank(userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        vm.stopPrank();
        vm.prank(scopeOwner);
        prot.setScopeRules(scopeName, true, false, true);
        vm.startPrank(userAddress);
        patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.prank(scopeOwner);
        prot.setScopeRules(scopeName, true, true, true);
        vm.prank(userAddress);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        // expect revert
        vm.prank(userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TransferBlockedByAssignment.selector, testFragmentLiteRefNFT, fragmentTokenId));
        testFragmentLiteRefNFT.transferFrom(userAddress, address(5), fragmentTokenId);
    }

    function testAssignNFT() public {
        vm.expectRevert(); // not assignable
        prot.assignNFT(address(1), 1, address(1), 1);

        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, scopeName));
        prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.AlreadyPatched.selector, address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT)));
        patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(userAddress);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(testFragmentLiteRefNFT)));
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        
        //Register artifactNFT to testPatchLiteRefNFT
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.SelfAssignmentNotAllowed.selector, address(testFragmentLiteRefNFT), fragmentTokenId));
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testFragmentLiteRefNFT), fragmentTokenId);

        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress);
        // cover called from non-owner/op with no allowUserAssign
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        
        vm.startPrank(scopeOwner);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        (address addr, uint256 tokenId) = testFragmentLiteRefNFT.getAssignedTo(fragmentTokenId);
        assertEq(addr, address(testPatchLiteRefNFT));
        assertEq(tokenId, patchTokenId);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);

        testFragmentLiteRefNFT.setTestLockOverride(true);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyAssigned.selector, address(testFragmentLiteRefNFT), fragmentTokenId));
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        testFragmentLiteRefNFT.setTestLockOverride(false);
        vm.stopPrank();
        
        vm.prank(userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TransferNotAllowed.selector, address(testPatchLiteRefNFT), patchTokenId));
        testPatchLiteRefNFT.transferFrom(userAddress, user2Address, patchTokenId);
    }

    function testScopeDoesNotExist() public {
        vm.startPrank(scopeOwner);
 
        uint256 fragmentTokenId1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragmentTokenId2 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 multi1 = testMultiFragmentNFT.mint(userAddress);
        //Register testPatchLiteRefNFT to testPatchLiteRefNFT
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        testFragmentLiteRefNFT.registerReferenceAddress(address(testMultiFragmentNFT));
        // Single
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, scopeName));
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId1, address(testFragmentLiteRefNFT), fragmentTokenId2);
        // Multi
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, scopeName));
        prot.assignNFT(address(testMultiFragmentNFT), multi1, address(testFragmentLiteRefNFT), fragmentTokenId2);
        address[] memory fragmentAddresses = new address[](1);
        uint256[] memory fragments = new uint256[](1);
        fragmentAddresses[0] = address(testFragmentLiteRefNFT);
        fragments[0] = fragmentTokenId1;
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, scopeName));
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testFragmentLiteRefNFT), fragmentTokenId2);
        // Claim scope to get assignments done to test unassign
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId1, address(testFragmentLiteRefNFT), fragmentTokenId2);
        prot.assignNFT(address(testMultiFragmentNFT), multi1, address(testFragmentLiteRefNFT), fragmentTokenId2);
        testFragmentLiteRefNFT.setScopeName("foo");
        testMultiFragmentNFT.setScopeName("foo");
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, "foo"));
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragmentTokenId1, address(testFragmentLiteRefNFT), fragmentTokenId2);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeDoesNotExist.selector, "foo"));
        prot.unassignNFT(address(testMultiFragmentNFT), multi1, address(testFragmentLiteRefNFT), fragmentTokenId2);
    }

    function testScopeTransferCannotBeFrontrun() public {
        address maliciousActor = address(120938);
        // A malicious actor attempts to preconfigure and transfer a scope to 0 so an unsuspecting actor claims it but it already has operators preconfigured
        vm.startPrank(maliciousActor);
        prot.claimScope("foo");
        prot.addOperator("foo", address(4));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ScopeTransferNotAllowed.selector, address(0)));
        prot.transferScopeOwnership("foo", address(0));
    }

    function testUserAssignNFT() public {
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, true, true, true);
        prot.addWhitelist(scopeName, address(testPatchLiteRefNFT));
        //Register artifactNFT to testPatchLiteRefNFT
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.stopPrank();
        vm.startPrank(userAddress);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
 
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(userAddress);
        uint256 user2FragmentTokenId = testFragmentLiteRefNFT.mint(user2Address);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);
 
        // Not whitelisted
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, scopeName, address(testFragmentLiteRefNFT)));
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.prank(scopeOwner);
        prot.addWhitelist(scopeName, address(testFragmentLiteRefNFT));

        // user 2 does not own either of these
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);

        // fragment and target have different owners
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        prot.assignNFT(address(testFragmentLiteRefNFT), user2FragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);

        // fragment and target have different owners
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.startPrank(userAddress);
        prot.assignNFT(address(testFragmentLiteRefNFT), user2FragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);

        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        (address addr, uint256 tokenId) = testFragmentLiteRefNFT.getAssignedTo(fragmentTokenId);
        assertEq(addr, address(testPatchLiteRefNFT));
        assertEq(tokenId, patchTokenId);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);
        vm.stopPrank();
        // not owned by user 2
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragmentTokenId);
        vm.startPrank(userAddress);
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragmentTokenId);
        // not currently assigned
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentNotAssigned.selector, address(testFragmentLiteRefNFT), fragmentTokenId));
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragmentTokenId);
    }

   function testDontAssignSomeoneElsesNFT() public {
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
 
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(user2Address);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), user2Address);
        //Register artifactNFT to testPatchLiteRefNFT
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, scopeOwner));
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
    }

   function testUnassignNFT() public {
        vm.expectRevert(); // not unassignable
        prot.unassignSingleNFT(address(1), 1);

        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));

        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        //Register testFragmentLiteRefNFT to testFragmentLiteRefNFT to allow recursion
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));

        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress);
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment2);
        vm.startPrank(scopeOwner);
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment2);
        // Now Id1 -> Id, unassign Id1 from Id
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment1);
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        // Now Id2 -> Id1 -> Id, unassign Id1 from Id
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment1);
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.startPrank(testBaseNFT.ownerOf(testBaseNFTTokenId));
        // transfer ownership of underlying asset (testBaseNFT)
        testBaseNFT.transferFrom(testBaseNFT.ownerOf(testBaseNFTTokenId), address(7), testBaseNFTTokenId);
        vm.stopPrank();
        vm.startPrank(scopeOwner);

        testFragmentLiteRefNFT.setGetLiteRefOverride(true, 0);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(testFragmentLiteRefNFT)));
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment2);
        testFragmentLiteRefNFT.setGetLiteRefOverride(false, 0);

        // Now Id2 -> Id1 -> Id where Id belongs to 7, unassign Id2 from Id1 and check new ownership
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment2);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragment2),  address(7));

        testFragmentLiteRefNFT.setGetAssignedToOverride(true, address(testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.RefNotFound.selector, address(testPatchLiteRefNFT), address(testFragmentLiteRefNFT), fragment2));
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment2);
        testFragmentLiteRefNFT.setGetAssignedToOverride(false, address(testPatchLiteRefNFT));
        vm.stopPrank();

        // try to transfer a patch directly - it should be blocked because it is soulbound
        assertEq(address(7), testPatchLiteRefNFT.ownerOf(patchTokenId)); // Report as soulbound
        vm.startPrank(userAddress); // Prank from underlying owner address
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TransferNotAllowed.selector, address(testPatchLiteRefNFT), patchTokenId));
        testPatchLiteRefNFT.transferFrom(userAddress, address(7), patchTokenId);
        vm.stopPrank();
    }

    function testBatchAssignNFT() public {
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        address[] memory fragmentAddresses = new address[](8);
        uint256[] memory fragments = new uint256[](8);

        for (uint8 i = 0; i < 8; i++) {
            fragmentAddresses[i] = address(testFragmentLiteRefNFT);
            fragments[i] = testFragmentLiteRefNFT.mint(userAddress);
        }

        // Fragment must be registered
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentUnregistered.selector, address(testFragmentLiteRefNFT)));
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        uint8 refId = testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));

        vm.stopPrank();
        // User may not assign without userAssign enabled
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);

        vm.prank(scopeOwner);
        prot.setScopeRules(scopeName, false, false, true);
        vm.startPrank(scopeOwner);
        // Whitelist enabled requires whitelisted (both patch and fragment)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, scopeName, address(testPatchLiteRefNFT)));
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        
        prot.addWhitelist(scopeName, address(testPatchLiteRefNFT));
        // Whitelist enabled requires whitelisted (now just fragment)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotWhitelisted.selector, scopeName, address(testFragmentLiteRefNFT)));
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        
        prot.addWhitelist(scopeName, address(testFragmentLiteRefNFT));

        // Inputs do not match length
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.BadInputLengths.selector));
        prot.batchAssignNFT(new address[](1), fragments, address(testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.prank(userAddress);
        testPatchLiteRefNFT.setFrozen(patchTokenId, true);
        // It's frozen (patch)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(testPatchLiteRefNFT), patchTokenId));
        vm.prank(scopeOwner);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        vm.prank(userAddress);
        testPatchLiteRefNFT.setFrozen(patchTokenId, false);

        vm.prank(userAddress);
        testFragmentLiteRefNFT.setFrozen(fragments[0], true);
        // It's frozen (fragment)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(testFragmentLiteRefNFT), fragments[0]));
        vm.prank(scopeOwner);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setFrozen(fragments[0], false);

        vm.prank(scopeOwner);
        testPatchLiteRefNFT.redactReferenceAddress(refId);
        // Fragment was redacted
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentRedacted.selector, address(testFragmentLiteRefNFT)));
        vm.prank(scopeOwner);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        vm.prank(scopeOwner);
        testPatchLiteRefNFT.unredactReferenceAddress(refId);

        address[] memory selfAddr = new address[](1);
        uint256[] memory selfFrag = new uint256[](1);
        selfAddr[0] = address(testPatchLiteRefNFT);
        selfFrag[0] = patchTokenId;
        // Self-assignment
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.SelfAssignmentNotAllowed.selector, selfAddr[0], selfFrag[0]));
        vm.prank(scopeOwner);     
        prot.batchAssignNFT(selfAddr, selfFrag, address(testPatchLiteRefNFT), patchTokenId);

        vm.prank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragments[0], true);
        // Fragment is locked
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Locked.selector, address(testFragmentLiteRefNFT), fragments[0]));
        vm.prank(scopeOwner);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragments[0], false);

        // test assigning fragments for another user
        address[] memory otherUserAddr = new address[](1);
        uint256[] memory otherUserFrag = new uint256[](1);
        otherUserAddr[0] = address(testFragmentLiteRefNFT);
        otherUserFrag[0] = testFragmentLiteRefNFT.mint(user2Address);
        // Target and fragment not same owner
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, scopeOwner));
        vm.prank(scopeOwner);     
        prot.batchAssignNFT(otherUserAddr, otherUserFrag, address(testPatchLiteRefNFT), patchTokenId);
    
        // finally a positive test case
        vm.prank(scopeOwner);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);

        for (uint8 i = 0; i < 8; i++) {
            (address addr, uint256 tokenId) = testFragmentLiteRefNFT.getAssignedTo(fragments[i]);
            assertEq(addr, address(testPatchLiteRefNFT));
            assertEq(tokenId, patchTokenId);
            assertEq(testFragmentLiteRefNFT.ownerOf(fragments[i]), userAddress);
            testFragmentLiteRefNFT.setTestLockOverride(true); // setup for next test part
        }

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.FragmentAlreadyAssigned.selector, fragmentAddresses[0], fragments[0]));
        vm.prank(scopeOwner);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
    }

    function testBatchUserPatchAssignNFT() public {
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, true, true, false);
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.stopPrank();

        vm.startPrank(userAddress);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        address[] memory fragmentAddresses = new address[](8);
        uint256[] memory fragments = new uint256[](8);
        uint256[] memory user2Fragments = new uint256[](8);

        for (uint8 i = 0; i < 8; i++) {
            fragmentAddresses[i] = address(testFragmentLiteRefNFT);
            fragments[i] = testFragmentLiteRefNFT.mint(userAddress);
            user2Fragments[i] = testFragmentLiteRefNFT.mint(user2Address);
        }
 
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);
        
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        prot.batchAssignNFT(fragmentAddresses, user2Fragments, address(testPatchLiteRefNFT), patchTokenId);

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress);
        prot.batchAssignNFT(fragmentAddresses, user2Fragments, address(testPatchLiteRefNFT), patchTokenId);

        // test assigning fragments for another user
        address[] memory otherUserAddr = new address[](1);
        uint256[] memory otherUserFrag = new uint256[](1);
        otherUserAddr[0] = address(testFragmentLiteRefNFT);
        otherUserFrag[0] = testFragmentLiteRefNFT.mint(user2Address);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress);
        prot.batchAssignNFT(otherUserAddr, otherUserFrag, address(testPatchLiteRefNFT), patchTokenId);

        // finally a positive test case
        vm.startPrank(userAddress);
        prot.batchAssignNFT(fragmentAddresses, fragments, address(testPatchLiteRefNFT), patchTokenId);

        for (uint8 i = 0; i < 8; i++) {
            (address addr, uint256 tokenId) = testFragmentLiteRefNFT.getAssignedTo(fragments[i]);
            assertEq(addr, address(testPatchLiteRefNFT));
            assertEq(tokenId, patchTokenId);
            assertEq(testFragmentLiteRefNFT.ownerOf(fragments[i]), userAddress);
        }
        vm.stopPrank();
    }

    function testTransferLogs() public {
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment3 = testFragmentLiteRefNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);

        //Register testFragmentLiteRefNFT to testFragmentLiteRefNFT to allow recursion
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));

        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        // Assign Id3 -> Id2
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment3, address(testFragmentLiteRefNFT), fragment2);
        vm.stopPrank();
        vm.expectEmit(true, true, true, true, address(testFragmentLiteRefNFT));
        emit Transfer(userAddress, user2Address, fragment2);
        vm.expectEmit(true, true, true, true, address(testFragmentLiteRefNFT));
        emit Transfer(userAddress, user2Address, fragment3);
        vm.expectEmit(true, true, true, true, address(testFragmentLiteRefNFT));
        emit Transfer(userAddress, user2Address, fragment1);
        vm.prank(userAddress);
        testFragmentLiteRefNFT.transferFrom(userAddress, user2Address, fragment1);
        assertEq(user2Address, testFragmentLiteRefNFT.ownerOf(fragment1));
        assertEq(user2Address, testFragmentLiteRefNFT.ownerOf(fragment2));
        assertEq(user2Address, testFragmentLiteRefNFT.ownerOf(fragment3));
    }

    function testUpdateOwnership() public {
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment3 = testFragmentLiteRefNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);

        //Register testFragmentLiteRefNFT to testFragmentLiteRefNFT to allow recursion
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));

        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        // Assign Id3 -> Id2
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment3, address(testFragmentLiteRefNFT), fragment2);
        vm.stopPrank();
        vm.prank(userAddress);
        // This won't actually transfer fragments 2 and 3
        testFragmentLiteRefNFT.transferFrom(userAddress, user2Address, fragment1);
        assertEq(user2Address, testFragmentLiteRefNFT.unassignedOwnerOf(fragment1));
        assertEq(userAddress, testFragmentLiteRefNFT.unassignedOwnerOf(fragment2));
        assertEq(userAddress, testFragmentLiteRefNFT.unassignedOwnerOf(fragment3));
        prot.updateOwnershipTree(address(testFragmentLiteRefNFT), fragment1);
        assertEq(user2Address, testFragmentLiteRefNFT.unassignedOwnerOf(fragment1));
        assertEq(user2Address, testFragmentLiteRefNFT.unassignedOwnerOf(fragment2));
        assertEq(user2Address, testFragmentLiteRefNFT.unassignedOwnerOf(fragment3));

        // test with patch
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        vm.prank(scopeOwner);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        vm.prank(userAddress);
        testBaseNFT.transferFrom(userAddress, user2Address, testBaseNFTTokenId);
        assertEq(user2Address, testPatchLiteRefNFT.ownerOf(patchTokenId));
        assertEq(userAddress, testPatchLiteRefNFT.unpatchedOwnerOf(patchTokenId));
        prot.updateOwnershipTree(address(testPatchLiteRefNFT), patchTokenId);
        assertEq(user2Address, testPatchLiteRefNFT.unpatchedOwnerOf(patchTokenId));
    }

    function testLocks() public {
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);
        testPatchworkNFT.mint(userAddress, 1);
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));

        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        //Register testFragmentLiteRefNFT to testFragmentLiteRefNFT to allow recursion
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.stopPrank();

        // cannot lock a patch
        assertEq(false, testPatchLiteRefNFT.locked(patchTokenId));
        vm.expectRevert();
        vm.prank(userAddress);
        testPatchLiteRefNFT.setLocked(patchTokenId, true);

        // can lock an unassigned fragment
        assertEq(false, testFragmentLiteRefNFT.locked(fragment1));
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragment1, true);
        assertEq(true, testFragmentLiteRefNFT.locked(fragment1));
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragment1, false);

        // only owner may lock
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        testFragmentLiteRefNFT.setLocked(fragment1, true);
        // only owner may lock
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        testPatchworkNFT.setLocked(1, true);

        // an assigned fragment is locked implicitly
        assertEq(false, testFragmentLiteRefNFT.locked(fragment1));
        vm.prank(scopeOwner);
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        assertEq(true, testFragmentLiteRefNFT.locked(fragment1));

        // cannot lock an assigned fragment
        vm.expectRevert();
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragment1, true);

        // cannot assign a locked fragment
        vm.startPrank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragment2, true);
        vm.expectRevert();
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testPatchLiteRefNFT), patchTokenId);

        // cannot transfer a locked fragment
        vm.expectRevert();
        testFragmentLiteRefNFT.transferFrom(userAddress, address(100), fragment2);
        testFragmentLiteRefNFT.setLocked(fragment2, false);
        testFragmentLiteRefNFT.transferFrom(userAddress, address(100), fragment2);
        assertEq(address(100), testFragmentLiteRefNFT.ownerOf(fragment2));
        vm.stopPrank();
    }

    function testFreezes() public {
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));

        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        //Register testFragmentLiteRefNFT to testFragmentLiteRefNFT to allow recursion
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.stopPrank();

        // Freeze the patch, shouldn't allow assignment of a child
        vm.prank(userAddress);
        testPatchLiteRefNFT.setFrozen(patchTokenId, true);
        assertEq(0, testPatchLiteRefNFT.getFreezeNonce(patchTokenId));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(testPatchLiteRefNFT), patchTokenId));
        vm.prank(scopeOwner);
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        vm.prank(userAddress);
        testPatchLiteRefNFT.setFrozen(patchTokenId, false);
        vm.startPrank(scopeOwner);
        assertEq(1, testPatchLiteRefNFT.getFreezeNonce(patchTokenId));
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);

        // Lock the patch, shouldn't allow unassignment of any child
        vm.stopPrank();
        vm.prank(userAddress);
        testPatchLiteRefNFT.setFrozen(patchTokenId, true);

        // It will return that the fragment is frozen even though the patch is the root cause, because all assigned to the patch inherit the freeze
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(testFragmentLiteRefNFT), fragment2));
        vm.prank(scopeOwner);
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment2);
        vm.prank(userAddress);
        testPatchLiteRefNFT.setFrozen(patchTokenId, false);
        assertEq(2, testPatchLiteRefNFT.getFreezeNonce(patchTokenId));
        vm.startPrank(scopeOwner);       
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment2);
        vm.stopPrank();
        vm.startPrank(scopeOwner);       
        // Unassign Id1 from patch
        prot.unassignSingleNFT(address(testFragmentLiteRefNFT), fragment1);
        vm.stopPrank();

        // Lock the fragment, shouldn't allow assignment to anything
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setFrozen(fragment1, true);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(testFragmentLiteRefNFT), fragment1));
        vm.prank(scopeOwner);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setFrozen(fragment2, true);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.Frozen.selector, address(testFragmentLiteRefNFT), fragment1));
        vm.prank(scopeOwner);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        vm.startPrank(userAddress);
        testFragmentLiteRefNFT.setFrozen(fragment2, false);

        // test transfers with lock nonce mismatch
        // first unassign the fragment b/c you can't unassign a locked one
        uint256 nonce = testFragmentLiteRefNFT.getFreezeNonce(fragment2);
        testFragmentLiteRefNFT.setFrozen(fragment2, true);
        testFragmentLiteRefNFT.setFrozen(fragment2, false); // nonce +1
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, address(testFragmentLiteRefNFT), fragment2));
        testFragmentLiteRefNFT.transferFromWithFreezeNonce(userAddress, user2Address, fragment2, nonce+1);
        assertEq(false, testFragmentLiteRefNFT.frozen(fragment2));
        testFragmentLiteRefNFT.setFrozen(fragment2, true);
        assertEq(true, testFragmentLiteRefNFT.frozen(fragment2));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, address(testFragmentLiteRefNFT), fragment2, nonce));
        testFragmentLiteRefNFT.transferFromWithFreezeNonce(userAddress, user2Address, fragment2, nonce);
        // now success
        testFragmentLiteRefNFT.transferFromWithFreezeNonce(userAddress, user2Address, fragment2, nonce+1);
        assertEq(user2Address, testFragmentLiteRefNFT.ownerOf(fragment2));
    }

    function testSpoofedTransfer1() public {
        vm.startPrank(scopeOwner);
        // create a patchworkliteref but manually put in an entry that isn't assigned to it (spoof ownership)
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        (uint64 ref, ) = testFragmentLiteRefNFT.getLiteReference(address(testFragmentLiteRefNFT), fragment2);
        testFragmentLiteRefNFT.addReference(fragment1, ref);
        // Should revert with data integrity error
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.DataIntegrityError.selector, address(testFragmentLiteRefNFT), fragment1, address(0), 0));
        vm.prank(userAddress);
        testFragmentLiteRefNFT.transferFrom(userAddress, user2Address, fragment1);
    }

    function testSpoofedTransfer2() public {
        vm.startPrank(scopeOwner);
        // create a patchworkliteref but manually put in an entry that isn't assigned to it (spoof ownership)
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        testFragmentLiteRefNFT.registerReferenceAddress(address(testBaseNFT));
        (uint64 ref, ) = testFragmentLiteRefNFT.getLiteReference(address(testBaseNFT), testBaseNFTTokenId);
        testFragmentLiteRefNFT.addReference(fragment1, ref);
        // Should revert with data integrity error
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotPatchworkAssignable.selector, address(testBaseNFT)));
        vm.prank(userAddress);
        testFragmentLiteRefNFT.transferFrom(userAddress, user2Address, fragment1);
    }

    function testLiteRefCollision() public {
        TestFragmentLiteRefNFT testFrag2 = new TestFragmentLiteRefNFT(address(prot));
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, false);
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFrag2));
        uint256 frag1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 frag2 = testFrag2.mint(userAddress);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        prot.assignNFT(address(testFragmentLiteRefNFT), frag1, address(testPatchLiteRefNFT), patchTokenId);
        // The second assign succeeding combined with the assertion that they are equal ref values means there is no collision in the scope.
        prot.assignNFT(address(testFrag2), frag2, address(testFragmentLiteRefNFT), frag1);
        // LiteRef IDs should match because it is idx1 tokenID 0 for both (0x1. 0x0)
        (uint64 lr1,) = testPatchLiteRefNFT.getLiteReference(address(testFragmentLiteRefNFT), frag1);
        (uint64 lr2,) = testFragmentLiteRefNFT.getLiteReference(address(testFrag2), frag2);
        assertEq(lr1, lr2);
    }
}