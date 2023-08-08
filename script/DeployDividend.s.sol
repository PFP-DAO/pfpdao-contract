// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {Dividend} from "../src/Dividend.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract DeployDividend is Script {
    Dividend implementationDividend;
    UUPSProxy proxyDividend;
    Dividend wrappedDividend;
    PFPDAOPool wrappedPool;
    PFPDAORole wrappedRole;

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address usdc = vm.envAddress("USDC");
        address initPool = vm.envAddress("POOL_ADDRESS");
        address initRole = vm.envAddress("ROLEA_ADDRESS");

        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);
        implementationDividend = new Dividend();
        proxyDividend = new UUPSProxy(address(implementationDividend), "");
        wrappedDividend = Dividend(address(proxyDividend));
        wrappedDividend.initialize(usdc, initPool, initRole);

        wrappedPool = PFPDAOPool(initPool);
        wrappedPool.setDividend(address(proxyDividend));
        require(address(wrappedPool.dividend()) == address(wrappedDividend), "dividend not set in pool");
        require(wrappedDividend.batch() == 1, "batch not 1");

        wrappedRole = PFPDAORole(initRole);
        wrappedRole.setDividend(address(proxyDividend));
        require(address(wrappedRole.dividend()) == address(wrappedDividend), "dividend not set in role");

        require(wrappedDividend.allowPools(initPool), "pool not allowed");
        require(wrappedDividend.rolesContracts(initRole), "role not allowed");
        vm.stopBroadcast();
    }
}
