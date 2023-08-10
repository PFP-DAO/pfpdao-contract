// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";

contract UpgradePFPDAOStyleVariantManager is Script {
    function run() public {
        address manager = vm.envAddress("STYLE_VARIANT_MANAGER");

        // 将代理合约包装成ABI，以支持更容易的调用
        PFPDAOStyleVariantManager wrappedManager = PFPDAOStyleVariantManager(manager);

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        PFPDAOStyleVariantManager implementationV2 = new PFPDAOStyleVariantManager();

        wrappedManager.upgradeTo(address(implementationV2));

        vm.stopBroadcast();
    }
}
