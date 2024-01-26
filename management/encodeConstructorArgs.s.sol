// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { PatchworkProtocol } from "src/PatchworkProtocol.sol";

contract EncodeConstructorArgs is Script {
    function run() public {
        address patchworkOwner = 0x7239aEc2fA59303BA68BEcE386BE2A9dDC72e63B;
        bytes memory encodedArgs = abi.encode(patchworkOwner);
        console.log("Encoded Constructor Args:", vm.toString(encodedArgs));
    }
}
