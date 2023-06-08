// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
// import "forge-std/console2.sol";

import {PFPDAOPool} from "../src/PFPDAOPool.sol";

contract SetNonce is Script {
    function run() public {
        address pool = vm.envAddress("POOL_ADDRESS");

        // 将代理合约包装成ABI，以支持更容易的调用
        PFPDAOPool wrappedPool = PFPDAOPool(pool);

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        wrappedPool.setActiveNonce(1);

        vm.stopBroadcast();
    }
}
