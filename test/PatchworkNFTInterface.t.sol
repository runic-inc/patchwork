// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkNFTInterface.sol";
import "../src/sampleNFTs/TestPatchLiteRefNFT.sol";
import "../src/sampleNFTs/TestFragmentLiteRefNFT.sol";

contract PatchworkNFTInterfaceTest is Test {
    TestPatchLiteRefNFT testPatchLiteRefNFT;
    TestFragmentLiteRefNFT testFragmentLiteRefNFT;
    bytes4 ERC165ID;

    function setUp() public {
        testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(1));
        testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(0x0000000000000000000000000000000000000000);
        ERC165ID = bytes4(0x01ffc9a7);
    }

    function testSupportsInterface() public {
        assertTrue(testPatchLiteRefNFT.supportsInterface(ERC165ID));
        assertTrue(testPatchLiteRefNFT.supportsInterface(type(IPatchworkNFT).interfaceId));
        assertTrue(testPatchLiteRefNFT.supportsInterface(type(IPatchworkLiteRef).interfaceId));
        assertTrue(testPatchLiteRefNFT.supportsInterface(type(IPatchworkPatch).interfaceId));

        assertTrue(testFragmentLiteRefNFT.supportsInterface(ERC165ID));
        assertTrue(testFragmentLiteRefNFT.supportsInterface(type(IPatchworkNFT).interfaceId));
        assertTrue(testFragmentLiteRefNFT.supportsInterface(type(IPatchworkAssignableNFT).interfaceId));
    }

}