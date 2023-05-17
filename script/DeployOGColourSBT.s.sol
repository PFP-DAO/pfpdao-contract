// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {OGColourSBT} from "../src/OGColourSBT.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract DeploySBT is Script {
    OGColourSBT implementationSBT;
    UUPSProxy proxySBT;
    OGColourSBT wrappedSBTV1;

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);
        implementationSBT = new OGColourSBT();
        proxySBT = new UUPSProxy(address(implementationSBT), "");
        wrappedSBTV1 = OGColourSBT(address(proxySBT));
        wrappedSBTV1.initialize();
        vm.stopBroadcast();
    }
}
