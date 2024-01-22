// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";
import { PatchworkProtocol } from "../src/PatchworkProtocol.sol";

contract DeterministicPatchworkDeploy is Script {

    address internal constant _DETERMINISTIC_CREATE2_FACTORY = 0x7A0D94F55792C434d74a40883C6ed8545E406D12;

    function run() public returns (PatchworkProtocol patchwork) {
        address patchworkOwner = vm.envAddress("PATCHWORK_OWNER");
        vm.startBroadcast();

        bytes memory pwCCode = type(PatchworkProtocol).creationCode;
        console.log("Patchwork creation code length: ", pwCCode.length);
        bytes memory creationBytecode = abi.encodePacked(pwCCode, abi.encode(patchworkOwner));
        (bool success, bytes memory returnData) = _DETERMINISTIC_CREATE2_FACTORY.call(creationBytecode);
        require(success, "Failed to deploy Patchwork");

        address patchworkAddress = address(uint160(bytes20(returnData)));
        patchwork = PatchworkProtocol(patchworkAddress);

        console.log("Deployed Patchwork contract at: ", patchworkAddress);
        vm.stopBroadcast();
    }
}
