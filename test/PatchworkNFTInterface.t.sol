// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkNFTInterface.sol";
import "../src/sampleNFTs/TestPatchLiteRefNFT.sol";
import "../src/sampleNFTs/TestFragmentLiteRefNFT.sol";

contract PatchworkNFTInterfaceTest is Test {
    Selector public selector;
    TestPatchLiteRefNFT public testPatchLiteRefNFT;
    TestFragmentLiteRefNFT public testFragmentLiteRefNFT;
    bytes4 ERC165ID;

    function setUp() public {
        testPatchLiteRefNFT = new TestPatchLiteRefNFT(address(1));
        selector = new Selector();
        testFragmentLiteRefNFT = new TestFragmentLiteRefNFT(0x0000000000000000000000000000000000000000);
        ERC165ID = bytes4(0x01ffc9a7);
    }

    function testInterfaceIds() public {
        //If this test fails it means we updated our patchwork NFT interface and need to update our selector id
        assertEq(selector.calculatePatchworkNFTSelector(), IPATCHWORKNFT_INTERFACE);
        assertEq(selector.calculateERC165Selector(), ERC165ID);
        assertEq(selector.calculatePatchworkAssignableNFTSelector(), IPATCHWORKASSIGNABLENFT_INTERFACE);
        assertEq(selector.calculatePatchworkLightRefSelector(), IPATCHWORKLITEREF_INTERFACE);
        assertEq(selector.calculatePatchworkPatchSelector(), IPATCHWORKPATCH_INTERFACE);
    }

    function testSupportsInterface() public {
        assertTrue(testPatchLiteRefNFT.supportsInterface(ERC165ID));
        assertTrue(testPatchLiteRefNFT.supportsInterface(IPATCHWORKNFT_INTERFACE));
        assertTrue(testPatchLiteRefNFT.supportsInterface(IPATCHWORKLITEREF_INTERFACE));
        assertTrue(testPatchLiteRefNFT.supportsInterface(IPATCHWORKPATCH_INTERFACE));

        assertTrue(testFragmentLiteRefNFT.supportsInterface(ERC165ID));
        assertTrue(testFragmentLiteRefNFT.supportsInterface(IPATCHWORKNFT_INTERFACE));
        assertTrue(testFragmentLiteRefNFT.supportsInterface(IPATCHWORKASSIGNABLENFT_INTERFACE));
    }

}