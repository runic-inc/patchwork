// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
@title Patchwork Contract Utilities
 */
library PatchworkUtils {
    /**
    @notice Converts uint64 raw data to an 8 character string
    @param raw the raw data
    @return out the string
    */
    function toString8(uint64 raw) internal pure returns (string memory out) {
        bytes memory byteArray = abi.encodePacked(bytes8(raw));
        // optimized shortcut out for full string value and no checks required later
        if (byteArray[7] != 0) {
            return string(byteArray);
        }
        return trimUp(byteArray);
    }

    /**
    @notice Converts uint128 raw data to a 16 character string
    @param raw the raw data
    @return out the string
    */
    function toString16(uint128 raw) internal pure returns (string memory out) {
        bytes memory byteArray = abi.encodePacked(bytes16(raw));
        // optimized shortcut out for full string value and no checks required later
        if (byteArray[15] != 0) {
            return string(byteArray);
        }
        return trimUp(byteArray);
    }

    /**
    @notice Converts uint256 raw data to a 32 character string
    @param raw the raw data
    @return out the string
    */
    function toString32(uint256 raw) internal pure returns (string memory out) {
        bytes memory byteArray = abi.encodePacked(bytes32(raw));
        // optimized shortcut out for full string value and no checks required later
        if (byteArray[31] != 0) {
            return string(byteArray);
        }
        return trimUp(byteArray);
    }

    /**
    @notice Trims a raw string to its null-terminated length
    @param byteArray the raw string
    @return out the trimmed string
    */
    function trimUp(bytes memory byteArray) internal pure returns (string memory out) {
        // uses about 40 more gas per call to be DRY, consider inlining to save gas if contract isn't too big
        uint nullPos = 0;
        while (true) {
            if (byteArray[nullPos] == 0) {
                break;
            }
            nullPos++;
        }
        bytes memory trimmedByteArray = new bytes(nullPos);
        for (uint256 i = 0; i < nullPos; i++) {
            trimmedByteArray[i] = byteArray[i];
        }
        out = string(trimmedByteArray);
    }

    /**
    @notice Converts a uint16 into a 2-byte array
    @param input the uint16
    @return bytes the array
    */
    function convertUint16ToBytes(uint16 input) internal pure returns (bytes memory) {
        // Extract the higher and lower bytes
        bytes1 high = bytes1(uint8(input >> 8));
        bytes1 low = bytes1(uint8(input & 0xFF));

        // Return the two bytes as a dynamic bytes array
        return abi.encodePacked(high, low);
    }

    /**
    @notice Converts a string to a uint256
    @param str the string to convert
    @return val the uint256 value
    */
    function strToUint256(string memory str) internal pure returns (uint256 val) {
        uint256 strLength;
        bytes memory str_ = bytes(str);
        // dynamic string or bytes memory layout has 1+ words: (length, valueBytes...)
        assembly {
            strLength := mload(str_)
        }
        if (strLength == 0) {
            val = 0;
        } else {
            bytes32 strBytes32;
            assembly {
                strBytes32 := mload(add(str_, 32))
            }
            val = uint256(strBytes32);
        }
    }
}