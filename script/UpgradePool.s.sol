// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {PFPDAOPool} from "../src/PFPDAOPool.sol";

contract UpgradePool is Script {
    function run() public {
        address pool = vm.envAddress("POOL_ADDRESS");

        // 将代理合约包装成ABI，以支持更容易的调用
        PFPDAOPool wrappedPoolV1 = PFPDAOPool(pool);

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        PFPDAOPool implementationV2 = new PFPDAOPool();

        wrappedPoolV1.upgradeTo(address(implementationV2));

        PFPDAOPool wrappedPoolV2 = PFPDAOPool(pool);

        // 第一期有4个角色，0是装备，1是legendary, 2-4是rare
        // uint16 upLegendaryId = 1;
        // uint16[] memory upRareIds = new uint16[](3);
        // upRareIds[0] = 2;
        // upRareIds[1] = 3;
        // upRareIds[2] = 4;
        // uint16[] memory normalLegendaryIds = new uint16[](0);
        // uint16[] memory normalRareIds = new uint16[](0);
        // uint16[] memory normalCommonIds = new uint16[](1);
        // normalCommonIds[0] = 0;
        // wrappedPoolV2.setUpLegendaryId(upLegendaryId);
        // wrappedPoolV2.setUpRareIds(upRareIds);
        // wrappedPoolV2.setNormalLegendaryIds(normalLegendaryIds);
        // wrappedPoolV2.setNormalRareIds(normalRareIds);
        // wrappedPoolV2.setNormalCommonIds(normalCommonIds);

        // wrappedPoolV2.setTreasury(vm.envAddress("TREASURY"));
        // wrappedPoolV2.setSigner(vm.envAddress("SIGNER"));

        wrappedPoolV2.setPriceLootOne(vm.envInt("PRICE_ONE"));
        wrappedPoolV2.setPriceLootTen(vm.envInt("PRICE_TEN"));
        address roleA = address(wrappedPoolV1.roleNFT());
        address equip = address(wrappedPoolV1.equipmentNFT());
        assert(roleA == vm.envAddress("ROLEA_ADDRESS"));
        assert(equip == vm.envAddress("EQUIP_ADDRESS"));

        assert(wrappedPoolV1.priceLootOne() == vm.envInt("PRICE_ONE"));
        assert(wrappedPoolV1.priceLootTen() == vm.envInt("PRICE_TEN"));

        assert(wrappedPoolV1.treasury() == vm.envAddress("TREASURY"));
        assert(wrappedPoolV1.signer() == vm.envAddress("SIGNER"));

        console2.log("getupLegendaryId:", wrappedPoolV2.upLegendaryId());
        console2.log("getUpRareIdsLength:", wrappedPoolV2.getUpRareIdsLength());
        console2.log("getNormalLegendaryIdsLength:", wrappedPoolV2.getNormalLegendaryIdsLength());
        console2.log("getNormalRareIdsLength:", wrappedPoolV2.getNormalRareIdsLength());
        console2.log("getNormalCommonIdsLength:", wrappedPoolV2.getNormalCommonIdsLength());

        vm.stopBroadcast();
    }
}
