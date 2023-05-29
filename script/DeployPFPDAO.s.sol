// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/console2.sol";
import "forge-std/Script.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";
// import {PFPDAOV2} from "../src/PFPDAOV2.sol";

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
        // vm read from .env

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        address treasury = deployer;
        // address treasury = vm.envAddress("TREASURY"); // mainnet

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
        address signer = vm.envAddress("SIGNER");
        wrappedPoolV1.initialize(address(proxyEquip), address(proxyRoleA));
        wrappedEquipV1.initialize();
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");

        wrappedPoolV1.setTreasury(treasury);
        wrappedPoolV1.setSigner(signer);
        wrappedPoolV1.setActiveNonce(1);

        vm.stopBroadcast();

        // PFPDAO implementationV1 = new PFPDAO();

        // deploy proxy contract and point it to implementation
        // proxy = new UUPSProxy(address(implementationV1), "");

        // wrap in ABI to support easier calls
        // wrappedProxyV1 = PFPDAO(address(proxy));

        // new implementation
        // PFPDAOV2 implementationV2 = new PFPDAOV2();
        // wrappedProxyV1.upgradeTo(address(implementationV2));

        // wrappedProxyV2 = PFPDAOV2(address(proxy));
    }
}
