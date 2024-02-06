// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";
import { PatchworkProtocol } from "../src/PatchworkProtocol.sol";
import { PatchworkProtocolAssigner } from "../src/PatchworkProtocolAssigner.sol";

contract DeterministicPatchworkDeploy is Script {

    function run() public {
        address patchworkOwner = vm.envAddress("PATCHWORK_OWNER");
        vm.startBroadcast();

        bytes32 salt = "1";
        PatchworkProtocolAssigner ppAssigner = new PatchworkProtocolAssigner{salt:salt}(patchworkOwner);
        console.log(address(ppAssigner));
        PatchworkProtocol pp = new PatchworkProtocol{salt:salt}(patchworkOwner, address(ppAssigner));
        console.log(address(pp));

        vm.stopBroadcast();
    }
}
