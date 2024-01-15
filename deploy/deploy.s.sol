// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

import {Defender} from "openzeppelin-foundry-upgrades/Defender.sol";
import {console} from "forge-std/console.sol";

contract DeployPatchworkScript is Script {
    function setUp() public {}

    function run() public {
        //string memory deployed = Defender.deployContract("PatchworkProtocol.sol:PatchworkProtocol");
        //console.log("Successfully deployed to address ", deployed);
    }
}