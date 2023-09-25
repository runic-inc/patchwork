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

    function setUp() public {
        testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(1));
        testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(0x0000000000000000000000000000000000000000);
    }

    function testSupportsInterface() public {
        assertTrue(testPatchLiteRefNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(testPatchLiteRefNFT.supportsInterface(type(IPatchworkNFT).interfaceId));
        assertTrue(testPatchLiteRefNFT.supportsInterface(type(IPatchworkLiteRef).interfaceId));
        assertTrue(testPatchLiteRefNFT.supportsInterface(type(IPatchworkPatch).interfaceId));

        assertTrue(testFragmentLiteRefNFT.supportsInterface(type(IERC165).interfaceId));
        assertTrue(testFragmentLiteRefNFT.supportsInterface(type(IPatchworkNFT).interfaceId));
        assertTrue(testFragmentLiteRefNFT.supportsInterface(type(IPatchworkAssignableNFT).interfaceId));
    }

}