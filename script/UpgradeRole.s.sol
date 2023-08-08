// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
// import "forge-std/console2.sol";

import {PFPDAORole} from "../src/PFPDAORole.sol";

contract UpgradeRole is Script {
    function run() public {
        address role = vm.envAddress("ROLEA_ADDRESS");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);

        vm.startBroadcast(deployer);

        PFPDAORole wrappedRoleV1 = PFPDAORole(role);
        // wrappedRoleV1.setStyleVariantManager(0xAF7C1085d3389EEB22C1F8dC0cC91dDd5b8B804a);

        PFPDAORole implementationV2 = new PFPDAORole();

        wrappedRoleV1.upgradeTo(address(implementationV2));

        // wrappedRoleV1.setRoleName(1, "Linger");
        // wrappedRoleV1.setRoleName(2, "Kazuki");
        // wrappedRoleV1.setRoleName(3, "Mila");
        // wrappedRoleV1.setRoleName(4, "Mico");
        // wrappedRoleV1.setEquipmentContract(vm.envAddress("EQUIP_ADDRESS"));

        // assert(keccak256(abi.encodePacked((wrappedRoleV1.roldIdToName(1)))) == keccak256(abi.encodePacked(("Linger"))));
        // assert(keccak256(abi.encodePacked((wrappedRoleV1.roldIdToName(2)))) == keccak256(abi.encodePacked(("Kazuki"))));
        // assert(keccak256(abi.encodePacked((wrappedRoleV1.roldIdToName(3)))) == keccak256(abi.encodePacked(("Mila"))));
        // assert(keccak256(abi.encodePacked((wrappedRoleV1.roldIdToName(4)))) == keccak256(abi.encodePacked(("Mico"))));
        // assert(wrappedRoleV1.equipmentContract() == vm.envAddress("EQUIP_ADDRESS"));
        vm.stopBroadcast();
    }
}
