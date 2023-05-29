// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";

contract SetUpPool is Script {
    function run() public {
        address pool = vm.envAddress("POOL_ADDRESS");
        address equip = vm.envAddress("EQUIP_ADDRESS");
        address roleA = vm.envAddress("ROLEA_ADDRESS");

        // 将代理合约包装成ABI，以支持更容易的调用
        PFPDAOPool wrappedPoolV1 = PFPDAOPool(pool);
        PFPDAOEquipment wrappedEquipV1 = PFPDAOEquipment(equip);
        PFPDAORole wrappedRoleAV1 = PFPDAORole(roleA);
        // PFPDAORole wrappedRoleBV1 = PFPDAORole(address(proxyRoleB));

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        // 第一期有4个角色，0是装备，1是legendary, 2-4是rare
        uint16 upLegendaryId = 1;
        uint16[] memory upRareIds = new uint16[](3);
        upRareIds[0] = 2;
        upRareIds[1] = 3;
        upRareIds[2] = 4;
        uint16[] memory normalLegendaryIds = new uint16[](0);
        uint16[] memory normalRareIds = new uint16[](0);
        uint16[] memory normalCommonIds = new uint16[](1);
        normalCommonIds[0] = 0;
        wrappedPoolV1.setUpLegendaryId(upLegendaryId);
        wrappedPoolV1.setUpRareIds(upRareIds);
        wrappedPoolV1.setNormalLegendaryIds(normalLegendaryIds);
        wrappedPoolV1.setNormalRareIds(normalRareIds);
        wrappedPoolV1.setNormalCommonIds(normalCommonIds);

        wrappedEquipV1.addActivePool(pool);
        wrappedRoleAV1.addActivePool(pool);

        vm.stopBroadcast();
    }
}
