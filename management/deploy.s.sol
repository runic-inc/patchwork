// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";
import { PatchworkProtocol } from "../src/PatchworkProtocol.sol";
import { PatchworkProtocolAssigner } from "../src/PatchworkProtocolAssigner.sol";

contract DeterministicPatchworkDeploy is Script {

    address internal constant _DETERMINISTIC_CREATE2_FACTORY = 0x7A0D94F55792C434d74a40883C6ed8545E406D12;

    function run() public {
        address patchworkOwner = vm.envAddress("PATCHWORK_OWNER");
        vm.startBroadcast();

        bytes memory creationCode = type(PatchworkProtocolAssigner).creationCode;
        bytes memory creationBytecode = abi.encodePacked(creationCode, abi.encode(patchworkOwner));
        (bool success, bytes memory returnData) = _DETERMINISTIC_CREATE2_FACTORY.call(creationBytecode);
        require(success, "Failed to deploy Assigner Module");
        address assignerAddress = address(uint160(bytes20(returnData)));
        console.log("Deployed Assigner module contract at: ", assignerAddress);

        creationCode = type(PatchworkProtocol).creationCode;
        creationBytecode = abi.encodePacked(creationCode, abi.encode(patchworkOwner), abi.encode(assignerAddress));
        (success, returnData) = _DETERMINISTIC_CREATE2_FACTORY.call(creationBytecode);
        require(success, "Failed to deploy Patchwork");
        address patchworkAddress = address(uint160(bytes20(returnData)));
        console.log("Deployed Patchwork contract at: ", patchworkAddress);

        vm.stopBroadcast();
    }
}
