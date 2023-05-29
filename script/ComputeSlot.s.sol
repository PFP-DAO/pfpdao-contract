// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {PFPDAORole} from "../src/PFPDAORole.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";

contract ComputeSlot is Script {
    PFPDAORole implementationRoleAV1;
    UUPSProxy proxyRoleA;
    PFPDAORole wrappedRoleAV1;

    function setUp() public {
        implementationRoleAV1 = new PFPDAORole();
        proxyRoleA = new UUPSProxy(address(implementationRoleAV1), "");
        wrappedRoleAV1 = PFPDAORole(address(proxyRoleA));
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");
    }

    function run() public view {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 1, 2, 1, 0);
        // uint256 tempSlot = 0x0000000000000000000000000000000000000000040100000004010000000000;
        console2.log("tempSlot", tempSlot);
    }
}
