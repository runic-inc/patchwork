// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./nfts/TestPatchLiteRefNFT.sol";

contract TestPatchLiteRefNFTTest is Test {
    TestPatchLiteRefNFT testNFT;

    function setUp() public {
        // TODO use real manager
        testNFT = new TestPatchLiteRefNFT(address(1));
    }

    function testPackUnpack() public {
        TestPatchLiteRefNFTMetadata memory data;
        data.artifactIDs[0] = 0;
        data.artifactIDs[1] = 5;
        data.artifactIDs[2] = 10;
        data.artifactIDs[3] = 15;
        data.artifactIDs[4] = 20;
        data.artifactIDs[5] = 25;
        data.artifactIDs[6] = 30;
        data.artifactIDs[7] = 35;
        data.xp = 1100;
        data.level = 2;
        data.xpLost = 200;
        data.stakedMade = 13;
        data.stakedCorrect = 7;
        data.evolution = 3;
        data.nickname = "kevbot7811111111";
        uint256[] memory slots = testNFT.packMetadata(data);
        console.logBytes32(bytes32(slots[0]));
        console.logBytes32(bytes32(slots[1]));
        console.logBytes32(bytes32(slots[2]));
        TestPatchLiteRefNFTMetadata memory data2 = testNFT.unpackMetadata(slots);
        assertEq(data2.artifactIDs[0], data.artifactIDs[0]);
        assertEq(data2.artifactIDs[1], data.artifactIDs[1]);
        assertEq(data2.artifactIDs[2], data.artifactIDs[2]);
        assertEq(data2.artifactIDs[3], data.artifactIDs[3]);
        assertEq(data2.artifactIDs[4], data.artifactIDs[4]);
        assertEq(data2.artifactIDs[5], data.artifactIDs[5]);
        assertEq(data2.artifactIDs[6], data.artifactIDs[6]);
        assertEq(data2.artifactIDs[7], data.artifactIDs[7]);
        assertEq(data2.xp, data.xp);
        assertEq(data2.level, data.level);
        assertEq(data2.xpLost, data.xpLost);
        assertEq(data2.stakedMade, data.stakedMade);
        assertEq(data2.stakedCorrect, data.stakedCorrect);
        assertEq(data2.evolution, data.evolution);
        assertEq(data2.nickname, data.nickname);
    }

    function testStoreLoad() public {
        TestPatchLiteRefNFTMetadata memory data;
        data.artifactIDs[0] = 0;
        data.artifactIDs[1] = 5;
        data.artifactIDs[2] = 10;
        data.artifactIDs[3] = 15;
        data.artifactIDs[4] = 20;
        data.artifactIDs[5] = 25;
        data.artifactIDs[6] = 30;
        data.artifactIDs[7] = 35;
        data.xp = 1100;
        data.level = 2;
        data.xpLost = 200;
        data.stakedMade = 13;
        data.stakedCorrect = 7;
        data.evolution = 3;
        data.nickname = "kevbot7811111111";
        testNFT.storeMetadata(1, data);
        TestPatchLiteRefNFTMetadata memory data2 = testNFT.loadMetadata(1);
        assertEq(data2.artifactIDs[0], data.artifactIDs[0]);
        assertEq(data2.artifactIDs[1], data.artifactIDs[1]);
        assertEq(data2.artifactIDs[2], data.artifactIDs[2]);
        assertEq(data2.artifactIDs[3], data.artifactIDs[3]);
        assertEq(data2.artifactIDs[4], data.artifactIDs[4]);
        assertEq(data2.artifactIDs[5], data.artifactIDs[5]);
        assertEq(data2.artifactIDs[6], data.artifactIDs[6]);
        assertEq(data2.artifactIDs[7], data.artifactIDs[7]);
        assertEq(data2.xp, data.xp);
        assertEq(data2.level, data.level);
        assertEq(data2.xpLost, data.xpLost);
        assertEq(data2.stakedMade, data.stakedMade);
        assertEq(data2.stakedCorrect, data.stakedCorrect);
        assertEq(data2.evolution, data.evolution);
        assertEq(data2.nickname, data.nickname);
    }

    function testPermissions() public {
        testNFT.storeMetadata(1, TestPatchLiteRefNFTMetadata([uint64(0), 0, 0, 0, 0, 0, 0, 0], 0, 0, 0, 0, 0, 0, ""));

        vm.prank(address(1337));
        vm.expectRevert();
        testNFT.setPermissions(address(1337), 0x1);
        vm.prank(address(1337));
        vm.expectRevert();
        testNFT.storeXP(1, 100);

        testNFT.setPermissions(address(1337), 0x1);
        vm.prank(address(1337));
        testNFT.storeXP(1, 100);
    }

    function testPermissionsOnMultipleFields() public {
        testNFT.storeMetadata(1, TestPatchLiteRefNFTMetadata([uint64(0), 0, 0, 0, 0, 0, 0, 0], 0, 0, 0, 0, 0, 0, ""));

        testNFT.setPermissions(address(1337), 0x3);

        vm.startPrank(address(1337));

        testNFT.storeXP(1, 1000);
        assertEq(testNFT.loadXP(1), 1000);
        assertEq(testNFT.loadLevel(1), 0);

        testNFT.storeLevel(1, 13);
        assertEq(testNFT.loadXP(1), 1000);
        assertEq(testNFT.loadLevel(1), 13);

        testNFT.storeXP(1, 65535);
        assertEq(testNFT.loadXP(1), 65535);
        assertEq(testNFT.loadLevel(1), 13);

        testNFT.storeLevel(1, 255);
        assertEq(testNFT.loadXP(1), 65535);
        assertEq(testNFT.loadLevel(1), 255);
    }

    function testUnusedFuncs() public view {
        testNFT.loadDynamicReferencePage(0, 0, 0);
        testNFT.getDynamicReferenceCount(0);
    }
}
