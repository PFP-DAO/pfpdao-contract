// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
// import "forge-std/console2.sol";

import {PFPDAOEquipMetadataDescriptor} from "../src/PFPDAOEquipMetadataDescriptor.sol";

contract UpgradeEquipMetadataDescriptor is Script {
    function run() public {
        address metadata = vm.envAddress("METADATA_ADDRESS");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);

        vm.startBroadcast(deployer);

        PFPDAOEquipMetadataDescriptor wrappedMetadata = PFPDAOEquipMetadataDescriptor(metadata);
        PFPDAOEquipMetadataDescriptor implementationV2 = new PFPDAOEquipMetadataDescriptor();
        wrappedMetadata.upgradeTo(address(implementationV2));

        vm.stopBroadcast();
    }
}
