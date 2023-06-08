// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
// import "forge-std/console2.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";

contract UpgradeEquip is Script {
    function run() public {
        address equip = vm.envAddress("EQUIP_ADDRESS");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);

        vm.startBroadcast(deployer);

        PFPDAOEquipment wrappedEquipV1 = PFPDAOEquipment(equip);
        PFPDAOEquipment implementationV2 = new PFPDAOEquipment();
        wrappedEquipV1.upgradeTo(address(implementationV2));

        vm.stopBroadcast();
    }
}
