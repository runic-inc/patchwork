// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/PatchworkUtils.sol";

contract PatchworkUtilsTest is Test {
    function testStringConversions() public {
        bytes8 b8;
        // 9/8
        bytes memory ns = bytes("abcdefghi");

        assembly {
            b8 := mload(add(ns, 32))
        }
        assertEq("abcdefgh", PatchworkUtils.toString8(uint64(b8)));
        // 8/8
        ns = bytes("abcdefgh");

        assembly {
            b8 := mload(add(ns, 32))
        }
        assertEq("abcdefgh", PatchworkUtils.toString8(uint64(b8)));
        // 4/8
        ns = bytes("abcd");

        assembly {
            b8 := mload(add(ns, 32))
        }
        assertEq("abcd", PatchworkUtils.toString8(uint64(b8)));
        // 0/8
        ns = bytes("");

        assembly {
            b8 := mload(add(ns, 32))
        }
        assertEq("", PatchworkUtils.toString8(uint64(b8)));
        bytes16 b16;
        // 16/16
        ns = bytes("abcdefghijklmnop");

        assembly {
            b16 := mload(add(ns, 32))
        }
        assertEq("abcdefghijklmnop", PatchworkUtils.toString16(uint128(b16)));
        // 17/16
        ns = bytes("abcdefghijklmnopq");

        assembly {
            b16 := mload(add(ns, 32))
        }
        assertEq("abcdefghijklmnop", PatchworkUtils.toString16(uint128(b16)));
        // 4/16
        ns = bytes("abcd");

        assembly {
            b16 := mload(add(ns, 32))
        }
        assertEq("abcd", PatchworkUtils.toString16(uint128(b16)));
        // 0/16
        ns = bytes("");

        assembly {
            b16 := mload(add(ns, 32))
        }
        assertEq("", PatchworkUtils.toString16(uint128(b16)));
        bytes32 b32;
        // 32/32
        ns = bytes("abcdefghijklmnopqrstuvwxyz123456");

        assembly {
            b32 := mload(add(ns, 32))
        }
        assertEq("abcdefghijklmnopqrstuvwxyz123456", PatchworkUtils.toString32(uint256(b32)));
        // 33/32
        ns = bytes("abcdefghijklmnopqrstuvwxyz1234567");

        assembly {
            b32 := mload(add(ns, 32))
        }
        assertEq("abcdefghijklmnopqrstuvwxyz123456", PatchworkUtils.toString32(uint256(b32)));
        // 4/32
        ns = bytes("abcd");

        assembly {
            b32 := mload(add(ns, 32))
        }
        assertEq("abcd", PatchworkUtils.toString32(uint256(b32)));
        // 0/32
        ns = bytes("");

        assembly {
            b32 := mload(add(ns, 32))
        }
        assertEq("", PatchworkUtils.toString32(uint256(b32)));
    }

    function testByteConversions() public {
        assertEq(abi.encodePacked(bytes1(uint8(0)), bytes1(uint8(0))), PatchworkUtils.convertUint16ToBytes(0));
        assertEq(abi.encodePacked(bytes1(uint8(1)), bytes1(uint8(2))), PatchworkUtils.convertUint16ToBytes(258));
    }
}