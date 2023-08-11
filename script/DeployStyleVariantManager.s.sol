// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";
import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";

contract DeployStyleVariantManager is Script {
    UUPSProxy proxy;
    PFPDAOStyleVariantManager implementation;
    PFPDAOStyleVariantManager wrappedManager;

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        address role = vm.envAddress("ROLEA_ADDRESS");
        address pool = vm.envAddress("POOL_ADDRESS");

        vm.startBroadcast(deployer);

        implementation = new PFPDAOStyleVariantManager();
        proxy = new UUPSProxy(address(implementation), "");

        wrappedManager = PFPDAOStyleVariantManager(address(proxy));
        wrappedManager.initialize(pool, role);

        PFPDAOPool wrappedPool = PFPDAOPool(pool);
        PFPDAORole wrappedRole = PFPDAORole(role);
        wrappedPool.setStyleVariantManager(address(wrappedManager));
        wrappedRole.setStyleVariantManager(address(wrappedManager));

        vm.stopBroadcast();
    }
}
