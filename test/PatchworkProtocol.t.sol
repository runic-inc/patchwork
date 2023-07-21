// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/sampleNFTs/TestPatchLiteRefNFT.sol";
import "../src/sampleNFTs/TestFragmentLiteRefNFT.sol";
import "../src/sampleNFTs/TestBaseNFT.sol";


contract PatchworkProtocolTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    PatchworkProtocol public prot;
    string scopeName;
    TestBaseNFT public testBaseNFT;
    TestPatchLiteRefNFT public testPatchLiteRefNFT;
    TestFragmentLiteRefNFT public testFragmentLiteRefNFT;

    address patchworkOwner; 
    address userAddress;
    address user2Address;
    address scopeOwner;

    function setUp() public {
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

    }

    function testClaimScope() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        assertEq(prot.getScopeOwner(scopeName), scopeOwner);
    }

    function testCreatePatchNFTNoVerification() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 tokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        assertEq(tokenId, 0);
    }

    function testCreatePatchNFTUnverified() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, true);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        vm.expectRevert("not whitelisted in scope");
        prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
    }

    function testCreatePatchNFTVerified() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, true);
        prot.addWhitelist(scopeName, address(testPatchLiteRefNFT));
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 tokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        assertEq(tokenId, 0);
    }

    function testUserPermissions() public {
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        prot.setScopeRules(scopeName, false, false, true);
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        prot.addWhitelist(scopeName, address(testPatchLiteRefNFT));
        prot.addWhitelist(scopeName, address(testFragmentLiteRefNFT));
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(userAddress);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);
        //Register artifactNFT to testPatchLiteRefNFT
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.stopPrank();
        vm.startPrank(userAddress);
        vm.expectRevert("not authorized");
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        vm.stopPrank();
        vm.prank(scopeOwner);
        prot.setScopeRules(scopeName, true, false, true);
        vm.startPrank(userAddress);
        patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        vm.expectRevert("not authorized");
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.prank(scopeOwner);
        prot.setScopeRules(scopeName, true, true, true);
        vm.prank(userAddress);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        // expect revert
        vm.prank(userAddress);
        vm.expectRevert("transfer blocked by assignment");
        testFragmentLiteRefNFT.transferFrom(userAddress, address(5), fragmentTokenId);
    }

    function testAssignNFT() public {
        vm.expectRevert(); // not assignable
        prot.assignNFT(address(1), 1, address(1), 1);

        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        vm.expectRevert("Scope does not yet exist");
        prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
        vm.expectRevert("already patched");
        patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
 
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(userAddress);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);

        //Register artifactNFT to testPatchLiteRefNFT
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));

        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        (address addr, uint256 tokenId) = testFragmentLiteRefNFT.getAssignedTo(fragmentTokenId);
        assertEq(addr, address(testPatchLiteRefNFT));
        assertEq(tokenId, patchTokenId);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), userAddress);
        vm.stopPrank();
        vm.prank(userAddress);
        vm.expectRevert("soulbound transfer not allowed");
        testPatchLiteRefNFT.transferFrom(userAddress, user2Address, patchTokenId);
    }

   function testDontAssignSomeoneElsesNFT() public {
        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));
 
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(user2Address);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragmentTokenId), user2Address);
        //Register artifactNFT to testPatchLiteRefNFT
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.expectRevert("not authorized");
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
    }

   function testUnassignNFT() public {
        vm.expectRevert(); // not unassignable
        prot.unassignNFT(address(1), 1);

        uint256 testBaseNFTTokenId = testBaseNFT.mint(userAddress);
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));

        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        //Register testFragmentLiteRefNFT to testFragmentLiteRefNFT to allow recursion
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));

        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragment2);
        // Now Id1 -> Id, unassign Id1 from Id
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragment1);
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);
        // Now Id2 -> Id1 -> Id, unassign Id1 from Id
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragment1);
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        vm.stopPrank();
        vm.startPrank(testBaseNFT.ownerOf(testBaseNFTTokenId));
        // transfer ownership of underlying asset (testBaseNFT)
        testBaseNFT.transferFrom(testBaseNFT.ownerOf(testBaseNFTTokenId), address(7), testBaseNFTTokenId);
        vm.stopPrank();
        vm.startPrank(scopeOwner);
        // Now Id2 -> Id1 -> Id where Id belongs to 7, unassign Id2 from Id1 and check new ownership
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragment2);
        assertEq(testFragmentLiteRefNFT.ownerOf(fragment2),  address(7));
        vm.stopPrank();

        // try to transfer a patch directly - it should be blocked because it is soulbound
        assertEq(address(7), testPatchLiteRefNFT.ownerOf(patchTokenId)); // Report as soulbound
        vm.startPrank(userAddress); // Prank from underlying owner address
        vm.expectRevert("soulbound transfer not allowed");
        testPatchLiteRefNFT.transferFrom(userAddress, address(7), patchTokenId);
        vm.stopPrank();
    }

    function testTransferLogs() public {
        uint256 fragment1 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment2 = testFragmentLiteRefNFT.mint(userAddress);
        uint256 fragment3 = testFragmentLiteRefNFT.mint(userAddress);

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);

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

        vm.startPrank(scopeOwner);
        prot.claimScope(scopeName);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), testBaseNFTTokenId, address(testPatchLiteRefNFT));

        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        //Register testFragmentLiteRefNFT to testFragmentLiteRefNFT to allow recursion
        testFragmentLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        vm.stopPrank();
        vm.prank(userAddress);
        testPatchLiteRefNFT.setLocked(patchTokenId, true);
        assertEq(0, testPatchLiteRefNFT.getLockNonce(patchTokenId));
        vm.prank(scopeOwner);
        vm.expectRevert("locked");
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        vm.prank(userAddress);
        testPatchLiteRefNFT.setLocked(patchTokenId, false);
        vm.startPrank(scopeOwner);
        assertEq(1, testPatchLiteRefNFT.getLockNonce(patchTokenId));
        // Assign Id1 -> Id
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment1, address(testPatchLiteRefNFT), patchTokenId);
        // Assign Id2 -> Id1
        prot.assignNFT(address(testFragmentLiteRefNFT), fragment2, address(testFragmentLiteRefNFT), fragment1);

        vm.stopPrank();
        vm.prank(userAddress);
        testPatchLiteRefNFT.setLocked(patchTokenId, true);
        vm.prank(scopeOwner);
        vm.expectRevert("locked");
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragment2);
        vm.prank(userAddress);
        testPatchLiteRefNFT.setLocked(patchTokenId, false);
        assertEq(2, testPatchLiteRefNFT.getLockNonce(patchTokenId));
        vm.startPrank(scopeOwner);       
        // Now Id2 -> Id1 -> Id, unassign Id2 from Id1
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragment2);
        vm.stopPrank();
        vm.prank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragment1, true);
        vm.prank(scopeOwner);
        vm.expectRevert("locked");
        prot.unassignNFT(address(testFragmentLiteRefNFT), fragment1);

        // test transfers with lock nonce mismatch
        vm.startPrank(userAddress);
        testFragmentLiteRefNFT.setLocked(fragment2, true);
        testFragmentLiteRefNFT.setLocked(fragment2, false); // nonce 1
        vm.expectRevert("not locked");
        testFragmentLiteRefNFT.transferFromWithLockNonce(userAddress, user2Address, fragment2, 0);
        testFragmentLiteRefNFT.setLocked(fragment2, true);
        vm.expectRevert("incorrect nonce");
        testFragmentLiteRefNFT.transferFromWithLockNonce(userAddress, user2Address, fragment2, 0);
        // now success
        testFragmentLiteRefNFT.transferFromWithLockNonce(userAddress, user2Address, fragment2, 1);
    }
}
