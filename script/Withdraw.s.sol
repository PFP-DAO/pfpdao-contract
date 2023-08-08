// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
// import "forge-std/console2.sol";

import {PFPDAOPool} from "../src/PFPDAOPool.sol";

contract Withdraw is Script {
    function run() public {
        address pool = vm.envAddress("POOL_ADDRESS");
        address treasury = 0x074D20bEa26943A30aF0bED695A2925Eed9B0f37;

        // 将代理合约包装成ABI，以支持更容易的调用
        PFPDAOPool wrappedPool = PFPDAOPool(pool);

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        wrappedPool.setTreasury(treasury);
        require(address(wrappedPool).balance > 4119 ether);
        wrappedPool.withdraw();
        require(address(treasury).balance > 4119 ether);

        vm.stopBroadcast();
    }
}
