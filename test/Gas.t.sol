// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

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

contract GasTest is Test {

    PatchworkProtocol _prot;

    string _scopeName;
    address _defaultUser;
    address _scopeOwner;
    address _patchworkOwner; 
    address _userAddress;
    address _user2Address;
    TestFragmentLiteRefNFT _lr;
    mapping(bytes32 => uint8) private _supportedInterfaceCache;
    mapping(address => string) private _scopeNameCache;

    function setUp() public {
        _defaultUser = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        _patchworkOwner = 0xF09CFF10D85E70D5AA94c85ebBEbD288756EFEd5;
        _userAddress = 0x10E4017cEd8648A9D5dAc21C82589C03C4835CCc;
        _user2Address = address(550001);
        _scopeOwner = 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5;

        vm.startPrank(_scopeOwner);
        _scopeName = "testscope";
        _lr = new TestFragmentLiteRefNFT(address(_prot));
        // call for every case as control / baseline
        _setupCache();
    }

    function testDirect165() public {
        assertTrue(_lr.supportsInterface(type(IERC721).interfaceId));
        assertTrue(_lr.supportsInterface(type(IPatchwork721).interfaceId));
        assertTrue(_lr.supportsInterface(type(IPatchworkScoped).interfaceId));
        assertTrue(_lr.supportsInterface(type(IPatchworkSingleAssignable).interfaceId));
    }

    function testStored165() public {
        assertEq(1, _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IERC721).interfaceId))]);
        assertEq(1, _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IPatchwork721).interfaceId))]);
        assertEq(1, _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IPatchworkScoped).interfaceId))]);
        assertEq(1, _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IPatchworkSingleAssignable).interfaceId))]);
    }

    function testDirectScopeName1() public {
        // control for cold access
        assertEq(_scopeName, _lr.getScopeName());
    }

    function testDirectScopeName4() public {
        // control for warm access
        assertEq(_scopeName, _lr.getScopeName());
        assertEq(_scopeName, _lr.getScopeName());
        assertEq(_scopeName, _lr.getScopeName());
        assertEq(_scopeName, _lr.getScopeName());
    }

    function testStoredScopeName1() public {
        // cold access
        assertEq(_scopeName, _scopeNameCache[address(_lr)]);
    }

    function testStoredScopeName4() public {
        // warm access
        assertEq(_scopeName, _scopeNameCache[address(_lr)]);
        assertEq(_scopeName, _scopeNameCache[address(_lr)]);
        assertEq(_scopeName, _scopeNameCache[address(_lr)]);
        assertEq(_scopeName, _scopeNameCache[address(_lr)]);
    }

    function _setupCache() private {
        if (_lr.supportsInterface(type(IERC721).interfaceId)) {
            _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IERC721).interfaceId))] = 1;
        }
        if (_lr.supportsInterface(type(IPatchwork721).interfaceId)) {
            _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IPatchwork721).interfaceId))] = 1;
        }
        if (_lr.supportsInterface(type(IPatchworkScoped).interfaceId)) {
            _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IPatchworkScoped).interfaceId))] = 1;
        }
        if (_lr.supportsInterface(type(IPatchworkSingleAssignable).interfaceId)) {
            _supportedInterfaceCache[keccak256(abi.encodePacked(address(_lr), type(IPatchworkSingleAssignable).interfaceId))] = 1;
        }
        _scopeNameCache[address(_lr)] = _lr.getScopeName();
    }
    
}