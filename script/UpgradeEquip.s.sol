// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
// import "forge-std/console2.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";

contract UpgradeEquip is Script {
    function run() public {
        address equip = vm.envAddress("EQUIP_ADDRESS");
        address metadata = vm.envAddress("METADATA_ADDRESS");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);

        vm.startBroadcast(deployer);

        PFPDAOEquipment wrappedEquipV1 = PFPDAOEquipment(equip);
        // PFPDAOEquipment implementationV2 = new PFPDAOEquipment();
        // wrappedEquipV1.upgradeTo(address(implementationV2));
        // wrappedEquipV1.setMetadataDescriptor(metadata);

        address[] memory allowedBurners = new address[](1);
        allowedBurners[0] = address(vm.envAddress("ROLEA_ADDRESS"));
        wrappedEquipV1.updateAllowedBurners(allowedBurners);

        vm.stopBroadcast();
    }
}
