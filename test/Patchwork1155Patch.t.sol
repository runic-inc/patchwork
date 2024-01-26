// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkProtocol.sol";
import "../src/PatchworkProtocolAssigner.sol";
import "./nfts/Test1155PatchNFT.sol";
import "./nfts/TestBase1155.sol";

contract Patchwork1155PatchTest is Test {

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
        _prot = new PatchworkProtocol(_patchworkOwner, address(new PatchworkProtocolAssigner(_patchworkOwner)));

        vm.startPrank(_scopeOwner);
        _scopeName = "testscope";
        _prot.claimScope(_scopeName);
        _prot.setScopeRules(_scopeName, false, false, false);
        
        vm.stopPrank();
    }

    function testScopeName() public {
        vm.prank(_scopeOwner);
        Test1155PatchNFT testAccountPatchNFT = new Test1155PatchNFT(address(_prot));
        assertEq(_scopeName, testAccountPatchNFT.getScopeName());
    }
    
    function testSupportsInterface() public {
        vm.prank(_scopeOwner);
        Test1155PatchNFT testAccountPatchNFT = new Test1155PatchNFT(address(_prot));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IPatchwork721).interfaceId));
        assertTrue(testAccountPatchNFT.supportsInterface(type(IPatchwork1155Patch).interfaceId));
        assertFalse(testAccountPatchNFT.supportsInterface(type(IPatchworkReversible1155Patch).interfaceId));

        TestReversible1155PatchNFT t = new TestReversible1155PatchNFT(address(_prot));
        assertTrue(t.supportsInterface(type(IERC165).interfaceId));
        assertTrue(t.supportsInterface(type(IERC721).interfaceId));
        assertTrue(t.supportsInterface(type(IERC4906).interfaceId));
        assertTrue(t.supportsInterface(type(IERC5192).interfaceId));
        assertTrue(t.supportsInterface(type(IPatchwork721).interfaceId));
        assertTrue(t.supportsInterface(type(IPatchwork1155Patch).interfaceId));
        assertTrue(t.supportsInterface(type(IPatchworkReversible1155Patch).interfaceId));
    }

    function test1155Patch() public {
        vm.startPrank(_scopeOwner);
        Test1155PatchNFT test1155PatchNFT = new Test1155PatchNFT(address(_prot));
        TestBase1155 base1155 = new TestBase1155();
        uint256 b = base1155.mint(_userAddress, 1, 5);
        vm.stopPrank();
        vm.startPrank(address(_prot));
        // basic mints should work
        test1155PatchNFT.mintPatch(_userAddress, IPatchwork1155Patch.PatchTarget(address(base1155), b, _userAddress));
        // global
        test1155PatchNFT.mintPatch(_userAddress, IPatchwork1155Patch.PatchTarget(address(base1155), b, address(0)));
        vm.stopPrank();      
        // no auth
        vm.expectRevert();  
        test1155PatchNFT.mintPatch(_userAddress, IPatchwork1155Patch.PatchTarget(address(base1155), b, _userAddress));
        // global
        vm.expectRevert();  
        test1155PatchNFT.mintPatch(_userAddress, IPatchwork1155Patch.PatchTarget(address(base1155), b, address(0)));
    }
    
    function test1155PatchProto() public {
        vm.startPrank(_scopeOwner);
        Test1155PatchNFT test1155PatchNFT = new Test1155PatchNFT(address(_prot));
        TestBase1155 base1155 = new TestBase1155();
        uint256 b = base1155.mint(_userAddress, 1, 5);

        // Account patch
        _prot.patch1155(_userAddress, address(base1155), b, _userAddress, address(test1155PatchNFT));
        
        // Account patch can't have duplicate
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ERC1155AlreadyPatched.selector, address(base1155), b, _userAddress, address(test1155PatchNFT)));
        _prot.patch1155(_userAddress, address(base1155), b, _userAddress, address(test1155PatchNFT));
        // Global patch
        _prot.patch1155(_scopeOwner, address(base1155), b, address(0), address(test1155PatchNFT));
        // Global patch can't have duplicate
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.ERC1155AlreadyPatched.selector, address(base1155), b, address(0), address(test1155PatchNFT)));
        _prot.patch1155(_scopeOwner, address(base1155), b, address(0), address(test1155PatchNFT));    
        // no user patching allowed
        vm.stopPrank();
        vm.startPrank(_userAddress);
        vm.expectRevert(abi.encodeWithSelector(IPatchworkProtocol.NotAuthorized.selector, _userAddress));
        _prot.patch1155(_scopeOwner, address(base1155), b, address(1), address(test1155PatchNFT));  
    }

    function test1155PatchUserPatch() public {
        vm.prank(_scopeOwner);
        _prot.setScopeRules(_scopeName, true, false, false);
        // Not same owner model, yes transferrable
        Test1155PatchNFT test1155PatchNFT = new Test1155PatchNFT(address(_prot));
        TestBase1155 base1155 = new TestBase1155();
        uint256 b = base1155.mint(_userAddress, 1, 5);
        // user can mint
        _prot.patch1155(_userAddress, address(base1155), b, _userAddress, address(test1155PatchNFT));
    }

    function testBurn() public {
        vm.startPrank(_scopeOwner);
        Test1155PatchNFT test1155PatchNFT = new Test1155PatchNFT(address(_prot));
        TestBase1155 base1155 = new TestBase1155();
        uint256 b = base1155.mint(_userAddress, 1, 5);
        uint256 pId = _prot.patch1155(_userAddress, address(base1155), b, _userAddress, address(test1155PatchNFT));
        test1155PatchNFT.burn(pId);
        // Should be able to re-patch now
        pId = _prot.patch1155(_userAddress, address(base1155), b, _userAddress, address(test1155PatchNFT));
    }

    function testReverseLookups() public {
        vm.startPrank(_scopeOwner);
        TestReversible1155PatchNFT test1155PatchNFT = new TestReversible1155PatchNFT(address(_prot));
        TestBase1155 base1155 = new TestBase1155();
        uint256 b = base1155.mint(_userAddress, 1, 5);
        uint256 pId = _prot.patch1155(_userAddress, address(base1155), b, _userAddress, address(test1155PatchNFT));
        assertEq(pId, test1155PatchNFT.getTokenIdByTarget(IPatchwork1155Patch.PatchTarget(address(base1155), b, _userAddress)));
    }
}