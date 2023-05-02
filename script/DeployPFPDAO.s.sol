// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";

import {PFPDAO} from "../src/PFPDAO.sol";
// import {PFPDAOV2} from "../src/PFPDAOV2.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";

contract DeployUUPS is Script {
    UUPSProxy proxy;
    PFPDAO wrappedProxyV1;
    // PFPDAOV2 wrappedProxyV2;

    function run() public {
        PFPDAO implementationV1 = new PFPDAO();

        // deploy proxy contract and point it to implementation
        proxy = new UUPSProxy(address(implementationV1), "");

        // wrap in ABI to support easier calls
        wrappedProxyV1 = PFPDAO(address(proxy));

        // new implementation
        // PFPDAOV2 implementationV2 = new PFPDAOV2();
        // wrappedProxyV1.upgradeTo(address(implementationV2));

        // wrappedProxyV2 = PFPDAOV2(address(proxy));
    }
}
