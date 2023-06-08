// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/console2.sol";
import "forge-std/Script.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

import {InitPFPDAO} from "./InitPFPDAO.s.sol";

contract Deploy is Script {
    PFPDAOPool implementationPoolV1;
    PFPDAOEquipment implementationEquipV1;
    PFPDAORole implementationRoleAV1;

    UUPSProxy proxyPool;
    UUPSProxy proxyEquip;
    UUPSProxy proxyRoleA;

    PFPDAOPool wrappedPoolV1;
    PFPDAOEquipment wrappedEquipV1;
    PFPDAORole wrappedRoleAV1;

    function setUp() public {}

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        implementationPoolV1 = new PFPDAOPool();
        implementationEquipV1 = new PFPDAOEquipment();
        implementationRoleAV1 = new PFPDAORole();

        // 部署代理合约并将其指向实现合约，这个是ERC1967Proxy
        proxyPool = new UUPSProxy(address(implementationPoolV1), "");
        proxyEquip = new UUPSProxy(address(implementationEquipV1), "");
        proxyRoleA = new UUPSProxy(address(implementationRoleAV1), "");

        // 将代理合约包装成ABI，以支持更容易的调用
        wrappedPoolV1 = PFPDAOPool(address(proxyPool));
        wrappedEquipV1 = PFPDAOEquipment(address(proxyEquip));
        wrappedRoleAV1 = PFPDAORole(address(proxyRoleA));

        // 初始化合约
        wrappedPoolV1.initialize(address(proxyEquip), address(proxyRoleA));
        wrappedEquipV1.initialize();
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");

        // 初始化设置
        address poolAddress = address(wrappedPoolV1);
        address equipAddress = address(wrappedEquipV1);
        address roleAAddress = address(wrappedRoleAV1);

        InitPFPDAO initPFPDAOContract = new InitPFPDAO();
        initPFPDAOContract.initAll(poolAddress, roleAAddress, equipAddress, deployer);

        console2.log("Pool address: %s", poolAddress);
        console2.log("Equip address: %s", equipAddress);
        console2.log("RoleA address: %s", roleAAddress);
        vm.stopBroadcast();
    }
}
