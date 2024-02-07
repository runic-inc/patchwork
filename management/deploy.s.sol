// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";
import { PatchworkProtocol } from "../src/PatchworkProtocol.sol";
import { PatchworkProtocolAssigner } from "../src/PatchworkProtocolAssigner.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract DeterministicPatchworkDeploy is Script {

    function run() public {
        address patchworkOwner = vm.envAddress("PATCHWORK_OWNER");
        address txFrom = msg.sender;

        vm.startBroadcast();

        console.log("sender: ", txFrom);
        console.log("receiver: ", patchworkOwner);
        bytes memory creationCode = type(PatchworkProtocolAssigner).creationCode;
        bytes memory creationBytecode = abi.encodePacked(creationCode, abi.encode(txFrom));
        console.log("assigner codehash: ", Strings.toHexString(uint256(keccak256(creationBytecode))));

        bytes32 salt = vm.envBytes32("ASSIGNER_SALT");
        console.log("assigner salt: ", Strings.toHexString(uint256(salt)));
        PatchworkProtocolAssigner ppAssigner = new PatchworkProtocolAssigner{salt:salt}(txFrom);
        console.log("assigner address: ", address(ppAssigner));

        creationCode = type(PatchworkProtocol).creationCode;
        creationBytecode = abi.encodePacked(creationCode, abi.encode(txFrom), abi.encode(address(ppAssigner)));
        console.log("patchwork codehash: ", Strings.toHexString(uint256(keccak256(creationBytecode))));

        salt = vm.envBytes32("PATCHWORK_SALT");
        console.log("patchwork salt: ", Strings.toHexString(uint256(salt)));
        PatchworkProtocol pp = new PatchworkProtocol{salt:salt}(txFrom, address(ppAssigner));
        console.log("patchwork address: ", address(pp));

        ppAssigner.transferOwnership(patchworkOwner);
        pp.transferOwnership(patchworkOwner);
        console.log("ppAssignerOwner: ", ppAssigner.owner());
        console.log("ppOwner: ", pp.owner());
        vm.stopBroadcast();
    }
}
