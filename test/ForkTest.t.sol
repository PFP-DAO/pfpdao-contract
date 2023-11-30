// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {PFPDAOCommonPool} from "../src/PFPDAOCommonPool.sol";

contract ForkTest is PRBTest {
    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("RPC_URL");
    address COMMON_POOL_ADDRESS = vm.envAddress("COMMON_POOL_ADDRESS");
    PFPDAOCommonPool commonPool;

    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        commonPool = PFPDAOCommonPool(COMMON_POOL_ADDRESS);
    }

    function testCanSelectFork() public {
        // select the fork
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
    }

    function testlootFork() public {
        vm.selectFork(mainnetFork);
        vm.prank(0x2D270fC5370EE30B71D5cC84c35B78b88D28A547);
        commonPool.loot1(6, 1523, true);
    }
}
