// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/sampleNFTs/TestPatchLiteRefNFT.sol";
import "../src/sampleNFTs/TestFragmentLiteRefNFT.sol";
import "../src/sampleNFTs/TestBaseNFT.sol";
import "../src/sampleNFTs/TestPatchworkNFT.sol";

contract PatchworkNFTBaseTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    PatchworkProtocol prot;
    TestBaseNFT testBaseNFT;
    TestPatchworkNFT testPatchworkNFT;
    TestPatchLiteRefNFT testPatchLiteRefNFT;
    TestFragmentLiteRefNFT testFragmentLiteRefNFT;

    string scopeName;
    address defaultUser;
    address scopeOwner;
    address patchworkOwner; 
    address userAddress;
    address user2Address;

    function setUp() public {
        defaultUser = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        patchworkOwner = 0xF09CFF10D85E70D5AA94c85ebBEbD288756EFEd5;
        userAddress = 0x10E4017cEd8648A9D5dAc21C82589C03C4835CCc;
        user2Address = address(550001);
        scopeOwner = 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5;

        vm.prank(patchworkOwner);
        prot = new PatchworkProtocol();
        scopeName = "testscope";
        vm.prank(scopeOwner);
        prot.claimScope(scopeName);
        vm.prank(scopeOwner);
        prot.setScopeRules(scopeName, false, false, false);

        vm.prank(userAddress);
        testBaseNFT = new TestBaseNFT();

        vm.prank(scopeOwner);
        testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(prot));
        vm.prank(scopeOwner);        
        testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(address(prot));
        vm.prank(scopeOwner);        
        testPatchworkNFT = new TestPatchworkNFT(address(prot));
    }

    function testScopeName() public {
        assertEq(scopeName, testPatchworkNFT.getScopeName());
        assertEq(scopeName, testPatchLiteRefNFT.getScopeName());
        assertEq(scopeName, testFragmentLiteRefNFT.getScopeName());
    }

    function testLoadStorePackedMetadataSlot() public {
        testPatchworkNFT.mint(userAddress, 1);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, defaultUser));
        testPatchworkNFT.storePackedMetadataSlot(1, 0, 0x505050);
        vm.prank(scopeOwner);
        testPatchworkNFT.storePackedMetadataSlot(1, 0, 0x505050);
        assertEq(0x505050, testPatchworkNFT.loadPackedMetadataSlot(1, 0));
    }

    function testTransferFrom() public {
        // TODO make sure these are calling checkTransfer on proto
        testPatchworkNFT.mint(userAddress, 1);
        assertEq(userAddress, testPatchworkNFT.ownerOf(1));
        vm.prank(userAddress);
        testPatchworkNFT.transferFrom(userAddress, user2Address, 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.prank(user2Address);
        testPatchworkNFT.safeTransferFrom(user2Address, userAddress, 1);
        assertEq(userAddress, testPatchworkNFT.ownerOf(1));
        vm.prank(userAddress);
        testPatchworkNFT.safeTransferFrom(userAddress, user2Address, 1, bytes("abcd"));
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));

        // test wrong user revert
        vm.startPrank(userAddress);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        testPatchworkNFT.transferFrom(user2Address, userAddress, 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        testPatchworkNFT.safeTransferFrom(user2Address, userAddress, 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        testPatchworkNFT.safeTransferFrom(user2Address, userAddress, 1, bytes("abcd"));
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
    }

    function testLockFreezeSeparation() public {
        testPatchworkNFT.mint(userAddress, 1);
        vm.startPrank(userAddress);
        assertFalse(testPatchworkNFT.locked(1));
        testPatchworkNFT.setLocked(1, true);
        assertTrue(testPatchworkNFT.locked(1));
        assertFalse(testPatchworkNFT.frozen(1));
        testPatchworkNFT.setFrozen(1, true);
        assertTrue(testPatchworkNFT.frozen(1));
        assertTrue(testPatchworkNFT.locked(1));
        testPatchworkNFT.setLocked(1, false);
        assertTrue(testPatchworkNFT.frozen(1));
        assertFalse(testPatchworkNFT.locked(1));
        testPatchworkNFT.setFrozen(1, false);
        assertFalse(testPatchworkNFT.frozen(1));
        assertFalse(testPatchworkNFT.locked(1));
        testPatchworkNFT.setFrozen(1, true);
        assertTrue(testPatchworkNFT.frozen(1));
        assertFalse(testPatchworkNFT.locked(1));
        testPatchworkNFT.setLocked(1, true);
        assertTrue(testPatchworkNFT.frozen(1));
        assertTrue(testPatchworkNFT.locked(1));
    }

    function testTransferFromWithFreezeNonce() public {
        // TODO make sure these are calling checkTransfer on proto
        testPatchworkNFT.mint(userAddress, 1);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, defaultUser));
        testPatchworkNFT.setFrozen(1, true);
        vm.prank(userAddress);
        testPatchworkNFT.setFrozen(1, true);
        assertEq(userAddress, testPatchworkNFT.ownerOf(1));
        vm.prank(userAddress);
        testPatchworkNFT.transferFromWithFreezeNonce(userAddress, user2Address, 1, 0);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.prank(user2Address);
        testPatchworkNFT.safeTransferFromWithFreezeNonce(user2Address, userAddress, 1, 0);
        assertEq(userAddress, testPatchworkNFT.ownerOf(1));
        vm.prank(userAddress);
        testPatchworkNFT.safeTransferFromWithFreezeNonce(userAddress, user2Address, 1, bytes("abcd"), 0);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));

        vm.startPrank(user2Address);
        // test not frozen revert
        testPatchworkNFT.setFrozen(1, false);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));

        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotFrozen.selector, testPatchworkNFT, 1));
        testPatchworkNFT.transferFromWithFreezeNonce(user2Address, userAddress, 1, 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotFrozen.selector, testPatchworkNFT, 1));
        testPatchworkNFT.safeTransferFromWithFreezeNonce(user2Address, userAddress, 1, 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotFrozen.selector, testPatchworkNFT, 1));
        testPatchworkNFT.safeTransferFromWithFreezeNonce(user2Address, userAddress, 1, bytes("abcd"), 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));

        // test incorrect nonce revert
        testPatchworkNFT.setFrozen(1, true);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.IncorrectNonce.selector, testPatchworkNFT, 1, 0));
        testPatchworkNFT.transferFromWithFreezeNonce(user2Address, userAddress, 1, 0);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.IncorrectNonce.selector, testPatchworkNFT, 1, 0));
        testPatchworkNFT.safeTransferFromWithFreezeNonce(user2Address, userAddress, 1, 0);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.IncorrectNonce.selector, testPatchworkNFT, 1, 0));
        testPatchworkNFT.safeTransferFromWithFreezeNonce(user2Address, userAddress, 1, bytes("abcd"), 0);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.stopPrank();

        // test wrong user revert
        vm.startPrank(userAddress);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        testPatchworkNFT.transferFromWithFreezeNonce(user2Address, userAddress, 1, 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        testPatchworkNFT.safeTransferFromWithFreezeNonce(user2Address, userAddress, 1, 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        testPatchworkNFT.safeTransferFromWithFreezeNonce(user2Address, userAddress, 1, bytes("abcd"), 1);
        assertEq(user2Address, testPatchworkNFT.ownerOf(1));
        vm.stopPrank();
    }

    function testLocks() public {
        uint256 baseTokenId = testBaseNFT.mint(userAddress);
        vm.prank(scopeOwner);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), baseTokenId, address(testPatchLiteRefNFT));
        bool locked = testPatchLiteRefNFT.locked(patchTokenId);
        assertFalse(locked);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.CannotLockSoulboundPatch.selector, testPatchLiteRefNFT));
        testPatchLiteRefNFT.setLocked(patchTokenId, true);
    }

    function testReferenceAddresses() public {
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, defaultUser));
        uint8 refIdx = testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        (uint64 ref, bool redacted) = testPatchLiteRefNFT.getLiteReference(address(testFragmentLiteRefNFT), 1);
        assertEq(0, ref);
        vm.prank(scopeOwner);
        refIdx = testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        (uint8 _id, bool _redacted) = testPatchLiteRefNFT.getReferenceId(address(testFragmentLiteRefNFT));
        assertEq(refIdx, _id);
        assertFalse(_redacted);
        (address _addr, bool _redacted2) = testPatchLiteRefNFT.getReferenceAddress(refIdx);
        assertEq(address(testFragmentLiteRefNFT), _addr);
        assertFalse(_redacted2);
        (ref, redacted) = testPatchLiteRefNFT.getLiteReference(address(testFragmentLiteRefNFT), 1);
        (address refAddr, uint256 tokenId) = testPatchLiteRefNFT.getReferenceAddressAndTokenId(ref);
        assertEq(address(testFragmentLiteRefNFT), refAddr);
        assertEq(1, tokenId);

        // test assign perms
        uint256 baseTokenId = testBaseNFT.mint(userAddress);
        uint256 fragmentTokenId = testFragmentLiteRefNFT.mint(userAddress);
        assertEq(userAddress, testFragmentLiteRefNFT.ownerOf(fragmentTokenId)); // TODO why doesn't this cover the branch != address(0)
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, user2Address));
        vm.prank(user2Address);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), baseTokenId, address(testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress); // must have user patch enabled
        patchTokenId = prot.createPatch(address(testBaseNFT), baseTokenId, address(testPatchLiteRefNFT));
        vm.prank(scopeOwner);
        patchTokenId = prot.createPatch(address(testBaseNFT), baseTokenId, address(testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress); // can't call directly
        testFragmentLiteRefNFT.assign(fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress); // must be owner/manager
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);

        vm.prank(scopeOwner);
        prot.assignNFT(address(testFragmentLiteRefNFT), fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        assertEq(userAddress, testFragmentLiteRefNFT.ownerOf(fragmentTokenId)); // TODO why doesn't this cover the branch != address(0)
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.FragmentAlreadyAssigned.selector, address(testFragmentLiteRefNFT), fragmentTokenId));
        vm.prank(scopeOwner); // not normal to call directly but need to test the correct error
        testFragmentLiteRefNFT.assign(fragmentTokenId, address(testPatchLiteRefNFT), patchTokenId);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, userAddress));
        vm.prank(userAddress); // can't call directly
        testFragmentLiteRefNFT.unassign(fragmentTokenId);

        uint256 newFrag = testFragmentLiteRefNFT.mint(userAddress);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, defaultUser));
        testPatchLiteRefNFT.redactReferenceAddress(refIdx);
        vm.prank(scopeOwner);
        testPatchLiteRefNFT.redactReferenceAddress(refIdx);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.FragmentRedacted.selector, address(testFragmentLiteRefNFT)));
        vm.prank(scopeOwner);
        prot.assignNFT(address(testFragmentLiteRefNFT), newFrag, address(testPatchLiteRefNFT), patchTokenId);
        
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.NotAuthorized.selector, defaultUser));
        testPatchLiteRefNFT.unredactReferenceAddress(refIdx);
        vm.prank(scopeOwner);
        testPatchLiteRefNFT.unredactReferenceAddress(refIdx);
        vm.prank(scopeOwner);
        prot.assignNFT(address(testFragmentLiteRefNFT), newFrag, address(testPatchLiteRefNFT), patchTokenId);
    }

    function testReferenceAddressErrors() public {
        vm.startPrank(scopeOwner);
        uint8 refIdx = testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        assertEq(1, refIdx);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.FragmentAlreadyRegistered.selector, address(testFragmentLiteRefNFT)));
        testPatchLiteRefNFT.registerReferenceAddress(address(testFragmentLiteRefNFT));
        // Fill ID 2 to 254 then test overflow
        for (uint8 i = 2; i < 255; i++) {
            refIdx = testPatchLiteRefNFT.registerReferenceAddress(address(bytes20(uint160(i))));
        }
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.OutOfIDs.selector));
        refIdx = testPatchLiteRefNFT.registerReferenceAddress(address(256));
    }
    
    function testBurn() public {
        uint256 baseTokenId = testBaseNFT.mint(userAddress);
        vm.prank(scopeOwner);
        uint256 patchTokenId = prot.createPatch(address(testBaseNFT), baseTokenId, address(testPatchLiteRefNFT));
        vm.expectRevert("unsupported");
        testPatchLiteRefNFT.burn(patchTokenId);
    }
    
    function testOnAssignedTransferError() public {
        vm.expectRevert();
        testFragmentLiteRefNFT.onAssignedTransfer(address(0), address(1), 1);
    }

    function testPatchworkCompatible() public {
        bytes1 r1 = testPatchLiteRefNFT.patchworkCompatible_();
        assertEq(0, r1);
        bytes2 r2 = testFragmentLiteRefNFT.patchworkCompatible_();
        assertEq(0, r2);
    }

    function testLiteref56bitlimit() public {
        vm.prank(scopeOwner);
        uint8 r1 = testFragmentLiteRefNFT.registerReferenceAddress(address(1));
        (uint64 ref, bool redacted) = testFragmentLiteRefNFT.getLiteReference(address(1), 1);
        assertEq((uint256(r1) << 56) + 1, ref);
        (ref, redacted) = testFragmentLiteRefNFT.getLiteReference(address(1), 0xFFFFFFFFFFFFFF);
        assertEq((uint256(r1) << 56) + 0xFFFFFFFFFFFFFF, ref);
        vm.expectRevert(abi.encodeWithSelector(PatchworkProtocol.UnsupportedTokenId.selector, 1 << 56));
        testFragmentLiteRefNFT.getLiteReference(address(1), 1 << 56);
    }

}