// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
// import "forge-std/console2.sol";

import {PFPDAORole} from "../src/PFPDAORole.sol";

contract UpgradeRole is Script {
    function run() public {
        address role = vm.envAddress("ROLEA_ADDRESS");

        // 将代理合约包装成ABI，以支持更容易的调用
        PFPDAORole wrappedRoleV1 = PFPDAORole(role);

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        // PFPDAORole implementationV2 = new PFPDAORole();

        // wrappedRoleV1.upgradeTo(address(implementationV2));

        wrappedRoleV1.setRoleName(1, "Linger");
        wrappedRoleV1.setRoleName(2, "Kazuki");
        wrappedRoleV1.setRoleName(3, "Mila");
        wrappedRoleV1.setRoleName(4, "Mico");

        vm.stopBroadcast();
    }
}
