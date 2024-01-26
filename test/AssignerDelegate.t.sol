// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol"; 
import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";

contract AssignerDelegateTest is Test {

    PatchworkProtocol _prot;
    address _defaultUser;
    address _patchworkOwner; 
    address _userAddress;
    address _user2Address;

    function setUp() public {
        _defaultUser = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        _patchworkOwner = 0xF09CFF10D85E70D5AA94c85ebBEbD288756EFEd5;
        _userAddress = 0x10E4017cEd8648A9D5dAc21C82589C03C4835CCc;
        _user2Address = address(550001);

        vm.startPrank(_patchworkOwner);
        _prot = new PatchworkProtocol(_patchworkOwner, address(new PatchworkProtocolAssigner(_patchworkOwner)));
        vm.stopPrank();
    }

    function testTimelock() public {
        // test wrong user
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _defaultUser));
        _prot.commitAssignerDelegate();
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _defaultUser));
        _prot.proposeAssignerDelegate(address(5));

        // test no proposal
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NoDelegateProposed.selector));
        vm.prank(_patchworkOwner);
        _prot.commitAssignerDelegate();

        // happy path propose
        vm.prank(_patchworkOwner);
        _prot.proposeAssignerDelegate(address(5));

        // timelock not met
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.TimelockNotElapsed.selector));
        vm.prank(_patchworkOwner);
        _prot.commitAssignerDelegate();

        // test cancel
        vm.prank(_patchworkOwner);
        _prot.proposeAssignerDelegate(address(0));

        // no proposal after cancel
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NoDelegateProposed.selector));
        vm.prank(_patchworkOwner);
        _prot.commitAssignerDelegate();
        
        // happy path propose, skip and commit
        vm.prank(_patchworkOwner);
        _prot.proposeAssignerDelegate(address(5));
        skip(2000000);
        vm.prank(_patchworkOwner);
        _prot.commitAssignerDelegate();

        // no proposal after commit
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NoDelegateProposed.selector));
        vm.prank(_patchworkOwner);
        _prot.commitAssignerDelegate();
    }
}