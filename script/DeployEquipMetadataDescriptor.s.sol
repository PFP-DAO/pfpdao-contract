// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {PFPDAOEquipMetadataDescriptor} from "../src/PFPDAOEquipMetadataDescriptor.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract DeployEquipMetadataDescriptor is Script {
    PFPDAOEquipMetadataDescriptor implementationMetadataDescriptor;
    UUPSProxy proxyMetadataDescriptor;
    PFPDAOEquipMetadataDescriptor wrappedMetadataDescriptor;

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);
        implementationMetadataDescriptor = new PFPDAOEquipMetadataDescriptor();
        proxyMetadataDescriptor = new UUPSProxy(address(implementationMetadataDescriptor), "");
        vm.stopBroadcast();
    }
}
