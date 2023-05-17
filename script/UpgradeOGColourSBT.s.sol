// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {OGColourSBT} from "../src/OGColourSBT.sol";

contract UpgradeOGColourSBT is Script {
    function run() public {
        address sbt = vm.envAddress("OGSBT_ADDRESS");

        // 将代理合约包装成ABI，以支持更容易的调用
        OGColourSBT wrappedSBTV1 = OGColourSBT(sbt);

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        OGColourSBT implementationV2 = new OGColourSBT();

        wrappedSBTV1.upgradeTo(address(implementationV2));

        vm.stopBroadcast();
    }
}
