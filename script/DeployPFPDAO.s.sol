// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/console2.sol";
import "forge-std/Script.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";
import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";
import {PFPDAOEquipMetadataDescriptor} from "../src/PFPDAOEquipMetadataDescriptor.sol";
import {OGColourSBT} from "../src/OGColourSBT.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract Deploy is Script {
    PFPDAOPool implementationPoolV1;
    PFPDAOEquipment implementationEquipV1;
    PFPDAORole implementationRoleAV1;
    PFPDAOStyleVariantManager implementationStyleManagerV1;
    PFPDAOEquipMetadataDescriptor implementationMetadataV1;
    OGColourSBT implementationSBT;

    UUPSProxy proxyPool;
    UUPSProxy proxyEquip;
    UUPSProxy proxyRoleA;
    UUPSProxy proxyStyleManager;
    UUPSProxy proxyMetadata;
    UUPSProxy proxySBT;

    PFPDAOPool wrappedPoolV1;
    PFPDAOEquipment wrappedEquipV1;
    PFPDAORole wrappedRoleAV1;
    PFPDAOStyleVariantManager wrappedStyleManagerV1;
    PFPDAOEquipMetadataDescriptor wrappedMetadataV1;
    OGColourSBT wrappedSBTV1;

    function setUp() public {}

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        implementationPoolV1 = new PFPDAOPool();
        implementationEquipV1 = new PFPDAOEquipment();
        implementationRoleAV1 = new PFPDAORole();
        implementationStyleManagerV1 = new PFPDAOStyleVariantManager();
        implementationMetadataV1 = new PFPDAOEquipMetadataDescriptor();
        implementationSBT = new OGColourSBT();

        // 部署代理合约并将其指向实现合约，这个是ERC1967Proxy
        proxyPool = new UUPSProxy(address(implementationPoolV1), "");
        proxyEquip = new UUPSProxy(address(implementationEquipV1), "");
        proxyRoleA = new UUPSProxy(address(implementationRoleAV1), "");
        proxyStyleManager = new UUPSProxy(address(implementationStyleManagerV1), "");
        proxyMetadata = new UUPSProxy(address(implementationMetadataV1), "");
        proxySBT = new UUPSProxy(address(implementationSBT), "");

        // 将代理合约包装成ABI，以支持更容易的调用
        wrappedPoolV1 = PFPDAOPool(address(proxyPool));
        wrappedEquipV1 = PFPDAOEquipment(address(proxyEquip));
        wrappedRoleAV1 = PFPDAORole(address(proxyRoleA));
        wrappedStyleManagerV1 = PFPDAOStyleVariantManager(address(proxyStyleManager));
        wrappedMetadataV1 = PFPDAOEquipMetadataDescriptor(address(proxyMetadata));
        wrappedSBTV1 = OGColourSBT(address(proxySBT));

        // 初始化合约
        wrappedPoolV1.initialize(address(proxyEquip), address(proxyRoleA));
        wrappedPoolV1.setStyleVariantManager(address(proxyStyleManager));
        wrappedEquipV1.initialize();
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");
        wrappedStyleManagerV1.initialize(address(proxyPool), address(proxyRoleA));
        wrappedMetadataV1.initialize();
        wrappedSBTV1.initialize();

        // 初始化设置
        address poolAddress = address(wrappedPoolV1);
        address equipAddress = address(wrappedEquipV1);
        address roleAAddress = address(wrappedRoleAV1);
        address styleManagerAddress = address(wrappedStyleManagerV1);
        address equipMetadataAddress = address(wrappedMetadataV1);
        address sbtAddress = address(wrappedSBTV1);

        console2.log("Pool address: %s", poolAddress);
        console2.log("Equip address: %s", equipAddress);
        console2.log("RoleA address: %s", roleAAddress);
        console2.log("StyleManager address: %s", styleManagerAddress);
        console2.log("EquipMetadata address: %s", equipMetadataAddress);
        console2.log("SBT address: %s", sbtAddress);

        // 设置nonce
        wrappedPoolV1.setActiveNonce(1);
        require(wrappedPoolV1.activeNonce() == 1);

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

        require(wrappedPoolV1.upLegendaryId() == 1);
        require(wrappedPoolV1.getUpRareIdsLength() == 3);
        require(wrappedPoolV1.getNormalLegendaryIdsLength() == 0);
        require(wrappedPoolV1.getNormalRareIdsLength() == 0);
        require(wrappedPoolV1.getNormalCommonIdsLength() == 1);

        // 设置loot价格
        wrappedPoolV1.setPriceLootOne(vm.envInt("PRICE_ONE"));
        wrappedPoolV1.setPriceLootTen(vm.envInt("PRICE_TEN"));
        require(wrappedPoolV1.priceLootOne() == vm.envInt("PRICE_ONE"));
        require(wrappedPoolV1.priceLootTen() == vm.envInt("PRICE_TEN"));

        // 设置signer
        wrappedPoolV1.setSigner(vm.envAddress("SIGNER"));
        require(wrappedPoolV1.signer() == vm.envAddress("SIGNER"));

        // 设置treasury
        wrappedPoolV1.setTreasury(vm.envAddress("TREASURY"));
        require(wrappedPoolV1.treasury() == vm.envAddress("TREASURY"));

        // 设置人物
        wrappedRoleAV1.setRoleName(1, "Linger");
        wrappedRoleAV1.setRoleName(2, "Kazuki");
        wrappedRoleAV1.setRoleName(3, "Mila");
        wrappedRoleAV1.setRoleName(4, "Mico");

        // 设置角色和装备合约
        wrappedRoleAV1.addActivePool(address(wrappedPoolV1));
        require(wrappedRoleAV1.isActivePool(address(wrappedPoolV1)));
        wrappedRoleAV1.setEquipmentContract(address(wrappedEquipV1));
        require(wrappedRoleAV1.equipmentContract() == address(wrappedEquipV1));

        wrappedEquipV1.addActivePool(address(wrappedPoolV1));
        require(wrappedRoleAV1.isActivePool(address(wrappedPoolV1)));
        require(wrappedEquipV1.isActivePool(address(wrappedPoolV1)));

        address[] memory allowedBurners = new address[](1);
        allowedBurners[0] = address(wrappedRoleAV1);
        wrappedEquipV1.updateAllowedBurners(allowedBurners);

        wrappedEquipV1.setMetadataDescriptor(address(wrappedMetadataV1));

        vm.stopBroadcast();
    }
}
