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

    PatchworkProtocol _prot;
    TestBaseNFT _testBaseNFT;
    TestPatchworkNFT _testPatchworkNFT;
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
        vm.prank(_scopeOwner);
        _prot.claimScope(_scopeName);
        vm.prank(_scopeOwner);
        _prot.setScopeRules(_scopeName, false, false, false);

        vm.prank(_userAddress);
        _testBaseNFT = new TestBaseNFT();

        vm.prank(_scopeOwner);
        _testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(_prot));
        vm.prank(_scopeOwner);        
        _testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(address(_prot));
        vm.prank(_scopeOwner);        
        _testPatchworkNFT = new TestPatchworkNFT(address(_prot));
    }

    function testScopeName() public {
        assertEq(_scopeName, _testPatchworkNFT.getScopeName());
        assertEq(_scopeName, _testPatchLiteRefNFT.getScopeName());
        assertEq(_scopeName, _testFragmentLiteRefNFT.getScopeName());
    }

    function testLoadStorePackedMetadataSlot() public {
        _testPatchworkNFT.mint(_userAddress, 1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchworkNFT.storePackedMetadataSlot(1, 0, 0x505050);
        vm.prank(_scopeOwner);
        _testPatchworkNFT.storePackedMetadataSlot(1, 0, 0x505050);
        assertEq(0x505050, _testPatchworkNFT.loadPackedMetadataSlot(1, 0));
    }

    function testTransferFrom() public {
        // TODO make sure these are calling checkTransfer on proto
        _testPatchworkNFT.mint(_userAddress, 1);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.transferFrom(_userAddress, _user2Address, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.prank(_user2Address);
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, 1);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.safeTransferFrom(_userAddress, _user2Address, 1, bytes("abcd"));
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        // test wrong user revert
        vm.startPrank(_userAddress);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.transferFrom(_user2Address, _userAddress, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFrom(_user2Address, _userAddress, 1, bytes("abcd"));
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
    }

    function testLockFreezeSeparation() public {
        _testPatchworkNFT.mint(_userAddress, 1);
        vm.startPrank(_userAddress);
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setLocked(1, true);
        assertTrue(_testPatchworkNFT.locked(1));
        assertFalse(_testPatchworkNFT.frozen(1));
        _testPatchworkNFT.setFrozen(1, true);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertTrue(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setLocked(1, false);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setFrozen(1, false);
        assertFalse(_testPatchworkNFT.frozen(1));
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setFrozen(1, true);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertFalse(_testPatchworkNFT.locked(1));
        _testPatchworkNFT.setLocked(1, true);
        assertTrue(_testPatchworkNFT.frozen(1));
        assertTrue(_testPatchworkNFT.locked(1));
    }

    function testTransferFromWithFreezeNonce() public {
        // TODO make sure these are calling checkTransfer on proto
        _testPatchworkNFT.mint(_userAddress, 1);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _defaultUser));
        _testPatchworkNFT.setFrozen(1, true);
        vm.prank(_userAddress);
        _testPatchworkNFT.setFrozen(1, true);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.transferFromWithFreezeNonce(_userAddress, _user2Address, 1, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.prank(_user2Address);
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 0);
        assertEq(_userAddress, _testPatchworkNFT.ownerOf(1));
        vm.prank(_userAddress);
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_userAddress, _user2Address, 1, bytes("abcd"), 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        vm.startPrank(_user2Address);
        // test not frozen revert
        _testPatchworkNFT.setFrozen(1, false);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, 1));
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, 1));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotFrozen.selector, _testPatchworkNFT, 1));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, bytes("abcd"), 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));

        // test incorrect nonce revert
        _testPatchworkNFT.setFrozen(1, true);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, 1, 0));
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, 1, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, 1, 0));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.IncorrectNonce.selector, _testPatchworkNFT, 1, 0));
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, bytes("abcd"), 0);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.stopPrank();

        // test wrong user revert
        vm.startPrank(_userAddress);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.transferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        _testPatchworkNFT.safeTransferFromWithFreezeNonce(_user2Address, _userAddress, 1, bytes("abcd"), 1);
        assertEq(_user2Address, _testPatchworkNFT.ownerOf(1));
        vm.stopPrank();
    }

    function testLocks() public {
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        uint256 patchTokenId = _prot.createPatch(address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        bool locked = _testPatchLiteRefNFT.locked(patchTokenId);
        assertFalse(locked);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.CannotLockSoulboundPatch.selector, _testPatchLiteRefNFT));
        _testPatchLiteRefNFT.setLocked(patchTokenId, true);
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
        uint256 fragmentTokenId = _testFragmentLiteRefNFT.mint(_userAddress);
        assertEq(_userAddress, _testFragmentLiteRefNFT.ownerOf(fragmentTokenId)); // TODO why doesn't this cover the branch != address(0)
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _user2Address));
        vm.prank(_user2Address);
        uint256 patchTokenId = _prot.createPatch(address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        vm.prank(_userAddress); // must have user patch enabled
        patchTokenId = _prot.createPatch(address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        vm.prank(_scopeOwner);
        patchTokenId = _prot.createPatch(address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
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

        uint256 newFrag = _testFragmentLiteRefNFT.mint(_userAddress);
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
    
    function testBurn() public {
        uint256 baseTokenId = _testBaseNFT.mint(_userAddress);
        vm.prank(_scopeOwner);
        uint256 patchTokenId = _prot.createPatch(address(_testBaseNFT), baseTokenId, address(_testPatchLiteRefNFT));
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedOperation.selector));
        _testPatchLiteRefNFT.burn(patchTokenId);
    }
    
    function testOnAssignedTransferError() public {
        vm.expectRevert();
        _testFragmentLiteRefNFT.onAssignedTransfer(address(0), address(1), 1);
    }

    function testPatchworkCompatible() public {
        bytes1 r1 = _testPatchLiteRefNFT.patchworkCompatible_();
        assertEq(0, r1);
        bytes2 r2 = _testFragmentLiteRefNFT.patchworkCompatible_();
        assertEq(0, r2);
    }

    function testLiteref56bitlimit() public {
        vm.prank(_scopeOwner);
        uint8 r1 = _testFragmentLiteRefNFT.registerReferenceAddress(address(1));
        (uint64 ref, bool redacted) = _testFragmentLiteRefNFT.getLiteReference(address(1), 1);
        assertEq((uint256(r1) << 56) + 1, ref);
        (ref, redacted) = _testFragmentLiteRefNFT.getLiteReference(address(1), 0xFFFFFFFFFFFFFF);
        assertEq((uint256(r1) << 56) + 0xFFFFFFFFFFFFFF, ref);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.UnsupportedTokenId.selector, 1 << 56));
        _testFragmentLiteRefNFT.getLiteReference(address(1), 1 << 56);
    }

}