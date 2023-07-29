// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
// import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {PFPDAOEquipment, NotBurner} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAOEquipMetadataDescriptor} from "../src/PFPDAOEquipMetadataDescriptor.sol";
import {PFPDAORole, Soulbound, InvalidSlot, NotAllowed, NotOwner} from "../src/PFPDAORole.sol";
import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";
import {Dividend} from "../src/Dividend.sol";
import {FiatToken} from "../src/FiatToken.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract _DividendTest is PRBTest {
    PFPDAOPool implementationPoolV1;
    PFPDAOEquipment implementationEquipV1;
    PFPDAORole implementationRoleAV1;
    PFPDAORole implementationRoleBV1;
    PFPDAOEquipMetadataDescriptor implementationMetadataDescriptor;
    PFPDAOStyleVariantManager implementationStyleManagerV1;
    Dividend implementationDividend;
    FiatToken implementationUSDC;

    UUPSProxy proxyPool;
    UUPSProxy proxyEquip;
    UUPSProxy proxyRoleA;
    UUPSProxy proxyRoleB;
    UUPSProxy proxyMetadataDescriptor;
    UUPSProxy proxyStyleManager;
    UUPSProxy proxyDividend;
    UUPSProxy proxyUSDC;

    PFPDAOPool wrappedPoolV1;
    PFPDAOEquipment wrappedEquipV1;
    PFPDAORole wrappedRoleAV1;
    PFPDAORole wrappedRoleBV1;
    PFPDAOEquipMetadataDescriptor wrappedMetadataDescriptor;
    PFPDAOStyleVariantManager wrappedStyleManagerV1;
    Dividend wrappedDividend;
    FiatToken wrappedUSDC;

    address signer;
    uint256 signerPrivateKey = 0xabcdf1234567890abcdef1234567890abcdef1234567890abcdef1234567890;
    address admin = address(0x01);
    address user1 = address(0x02);
    address treasury = address(0x03);
    address user2 = address(0x04);

    function setUp() public {
        signer = vm.addr(signerPrivateKey);

        implementationPoolV1 = new PFPDAOPool();
        implementationEquipV1 = new PFPDAOEquipment();
        implementationRoleAV1 = new PFPDAORole();
        implementationRoleBV1 = new PFPDAORole();
        implementationMetadataDescriptor = new PFPDAOEquipMetadataDescriptor();
        implementationStyleManagerV1 = new PFPDAOStyleVariantManager();
        implementationDividend = new Dividend();
        implementationUSDC = new FiatToken();

        // 部署代理合约并将其指向实现合约，这个是ERC1967Proxy
        proxyPool = new UUPSProxy(address(implementationPoolV1), "");
        proxyEquip = new UUPSProxy(address(implementationEquipV1), "");
        proxyRoleA = new UUPSProxy(address(implementationRoleAV1), "");
        proxyRoleB = new UUPSProxy(address(implementationRoleBV1), "");
        proxyMetadataDescriptor = new UUPSProxy(address(implementationMetadataDescriptor), "");
        proxyStyleManager = new UUPSProxy(address(implementationStyleManagerV1), "");
        proxyDividend = new UUPSProxy(address(implementationDividend), "");
        proxyUSDC = new UUPSProxy(address(implementationUSDC), "");

        // 将代理合约包装成ABI，以支持更容易的调用
        wrappedPoolV1 = PFPDAOPool(address(proxyPool));
        wrappedEquipV1 = PFPDAOEquipment(address(proxyEquip));
        wrappedRoleAV1 = PFPDAORole(address(proxyRoleA));
        wrappedRoleBV1 = PFPDAORole(address(proxyRoleB));
        wrappedMetadataDescriptor = PFPDAOEquipMetadataDescriptor(address(proxyMetadataDescriptor));
        wrappedStyleManagerV1 = PFPDAOStyleVariantManager(address(proxyStyleManager));
        wrappedDividend = Dividend(address(proxyDividend));
        wrappedUSDC = FiatToken(address(proxyUSDC));

        // 初始化合约
        wrappedPoolV1.initialize(address(proxyEquip), address(proxyRoleA));
        wrappedPoolV1.setStyleVariantManager(address(proxyStyleManager));
        wrappedEquipV1.initialize();
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");
        wrappedRoleBV1.initialize("PFPDAORoleB", "PFPRB");
        wrappedStyleManagerV1.initialize(address(wrappedPoolV1), address(wrappedRoleAV1));
        wrappedRoleAV1.setStyleVariantManager(address(proxyStyleManager));
        wrappedRoleBV1.setStyleVariantManager(address(proxyStyleManager));
        wrappedDividend.initialize(address(wrappedUSDC), address(wrappedPoolV1), address(wrappedRoleAV1));
        wrappedUSDC.initialize();

        // 第一期有4个角色，0是装备，1是legendary, 2-4是rare
        uint16 upSSSId = 1;
        uint16[] memory upSSIds = new uint16[](3);
        upSSIds[0] = 2;
        upSSIds[1] = 3;
        upSSIds[2] = 4;
        uint16[] memory nSSSIds = new uint16[](0);
        uint16[] memory nSSIds = new uint16[](0);
        uint16[] memory nSIds = new uint16[](1);
        nSIds[0] = 0;
        wrappedPoolV1.setupSSSId(upSSSId);
        wrappedPoolV1.setupSSIds(upSSIds);
        wrappedPoolV1.setnSSSIds(nSSSIds);
        wrappedPoolV1.setnSSIds(nSSIds);
        wrappedPoolV1.setnSIds(nSIds);

        wrappedEquipV1.addActivePool(address(proxyPool));
        wrappedRoleAV1.addActivePool(address(proxyPool));

        wrappedRoleAV1.setRoleName(1, "Linger");
        wrappedRoleAV1.setRoleName(2, "Kazuki");
        wrappedRoleAV1.setRoleName(3, "Mila");
        wrappedRoleAV1.setRoleName(4, "Mico");

        wrappedPoolV1.setTreasury(treasury);
        wrappedPoolV1.setSigner(signer);
        wrappedPoolV1.setDividend(address(proxyDividend));

        wrappedRoleAV1.setEquipmentContract(address(proxyEquip));
        wrappedEquipV1.setMetadataDescriptor(address(proxyMetadataDescriptor));
        wrappedRoleAV1.setDividend(address(proxyDividend));

        address[] memory allowedBurners = new address[](1);
        allowedBurners[0] = address(wrappedRoleAV1);
        wrappedEquipV1.updateAllowedBurners(allowedBurners);

        // vm mock user1 100 eth
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);

        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(); // 1
        wrappedPoolV1.loot10{value: 22 ether}(); // 2
        wrappedPoolV1.loot10{value: 22 ether}(); // 3
        wrappedPoolV1.loot10{value: 22 ether}(); // 4
        vm.stopPrank();

        vm.startPrank(user2);
        wrappedPoolV1.loot10{value: 22 ether}(); // 5
        wrappedPoolV1.loot10{value: 22 ether}(); // 6
        vm.stopPrank();

        wrappedRoleAV1.setRoleLevelAndExp(1, 19, 56); // upgrade to 19 56
        wrappedRoleAV1.setRoleLevelAndExp(3, 19, 56); // upgrade to 19 56
        wrappedRoleAV1.setRoleLevelAndExp(5, 19, 56); // upgrade to 19 56

        vm.startPrank(user1);
        uint256[] memory idsToBurnUser1 = new uint256[](1);
        idsToBurnUser1[0] = 2;
        wrappedRoleAV1.awake(1, idsToBurnUser1); // 1

        uint256[] memory idsToBurnUser12 = new uint256[](1);
        idsToBurnUser12[0] = 4;
        wrappedRoleAV1.awake(3, idsToBurnUser12); // 3
        vm.stopPrank();

        uint256[] memory idsToBurnUser2 = new uint256[](1);
        idsToBurnUser2[0] = 6;
        vm.prank(user2);
        wrappedRoleAV1.awake(5, idsToBurnUser2); // 5
    }

    function testIntialize() public {
        assertEq(wrappedDividend.allowPools(address(proxyPool)), true);
        assertEq(wrappedDividend.rolesContracts(address(proxyRoleA)), true);
        assertEq(wrappedDividend.batch(), 1);
        assertEq(address(wrappedDividend.usdcAddress()), address(wrappedUSDC));
        assertEq(address(wrappedRoleAV1.dividend()), address(proxyDividend));

        assertEq(wrappedDividend.captainRightDenominator(3), 60);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 40); // user1 has 2 level 20 mila
        assertEq(wrappedDividend.addressCaptainRight(user2, 3), 20); // user2 has 1 level 20 mila

        assertEq(wrappedDividend.roleIdPoolBalance(3), 0);
    }

    function testLevelChangeRight() public {
        vm.startPrank(user1);
        uint256[] memory equipsToBurn = new uint256[](2);
        equipsToBurn[0] = 1; // level to 21
        equipsToBurn[1] = 2; // level to 22
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipsToBurn);
        vm.stopPrank();

        assertEq(wrappedDividend.captainRightDenominator(3), 22 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 22 + 20);

        vm.startPrank(user2);
        uint256[] memory equipsToBurn2 = new uint256[](1);
        equipsToBurn2[0] = 5; // level to 21
        wrappedRoleAV1.levelUpByBurnEquipments(5, equipsToBurn2);
        vm.stopPrank();

        assertEq(wrappedDividend.captainRightDenominator(3), 22 + 20 + 21);
        assertEq(wrappedDividend.addressCaptainRight(user2, 3), 21);

        wrappedRoleAV1.setRoleLevelAndExp(1, 38, 340); // upgrade to 38 340
        uint256[] memory equipsToBurn3 = new uint256[](1);
        equipsToBurn3[0] = 3; // level to 39
        vm.prank(user1);
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipsToBurn3);
        assertEq(wrappedDividend.captainRightDenominator(3), 39 + 20 + 21);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 39 + 20);

        wrappedRoleAV1.setRoleLevelAndExp(1, 40, 0); // upgrade to 40 0
        assertEq(wrappedDividend.captainRightDenominator(3), 400 + 20 + 21);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 400 + 20);
    }

    function testAwakeChangeRightSS() public {
        address[] memory to = new address[](1);
        to[0] = user1;
        for (uint256 i = 0; i < 14; i++) {
            wrappedRoleAV1.airdrop(to, 3, 1);
        }

        wrappedRoleAV1.setRoleLevelAndExp(1, 39, 374);
        assertEq(wrappedDividend.captainRightDenominator(3), 39 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 39 + 20);

        vm.prank(user1);
        uint256[] memory burn2_role_39_to_40 = new uint256[](2);
        burn2_role_39_to_40[0] = 7;
        burn2_role_39_to_40[1] = 8;
        wrappedRoleAV1.awake(1, burn2_role_39_to_40);

        assertEq(wrappedDividend.captainRightDenominator(3), 400 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 400 + 20);

        wrappedRoleAV1.setRoleLevelAndExp(1, 59, 2516);
        assertEq(wrappedDividend.captainRightDenominator(3), 590 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 590 + 20);

        vm.prank(user1);
        uint256[] memory burn4_role_59_to_60 = new uint256[](4);
        burn4_role_59_to_60[0] = 9;
        burn4_role_59_to_60[1] = 10;
        burn4_role_59_to_60[2] = 11;
        burn4_role_59_to_60[3] = 12;
        wrappedRoleAV1.awake(1, burn4_role_59_to_60);

        assertEq(wrappedDividend.captainRightDenominator(3), 900 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 900 + 20);

        wrappedRoleAV1.setRoleLevelAndExp(1, 79, 16929);
        assertEq(wrappedDividend.captainRightDenominator(3), 1185 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 1185 + 20);

        vm.prank(user1);
        uint256[] memory burn8_role_79_to_80 = new uint256[](8);
        burn8_role_79_to_80[0] = 13;
        burn8_role_79_to_80[1] = 14;
        burn8_role_79_to_80[2] = 15;
        burn8_role_79_to_80[3] = 16;
        burn8_role_79_to_80[4] = 17;
        burn8_role_79_to_80[5] = 18;
        burn8_role_79_to_80[6] = 19;
        burn8_role_79_to_80[7] = 20;
        wrappedRoleAV1.awake(1, burn8_role_79_to_80);

        assertEq(wrappedDividend.captainRightDenominator(3), 3200 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 3200 + 20);
    }

    function testAwakeChangeRightSSS() public {
        address[] memory to = new address[](1);
        to[0] = user1;
        // burn 1 2 4 8 16 to 90, start from 7
        for (uint256 i = 0; i < 32; i++) {
            wrappedRoleAV1.airdrop(to, 1, 2);
        }

        uint256 mainId = 7;

        wrappedRoleAV1.setRoleLevelAndExp(mainId, 19, wrappedRoleAV1.expTable(18));
        assertEq(wrappedDividend.captainRightDenominator(1), 0);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 0);

        vm.prank(user1);
        uint256[] memory burn1_role_19_to_20 = new uint256[](1);
        burn1_role_19_to_20[0] = mainId + 1;
        wrappedRoleAV1.awake(mainId, burn1_role_19_to_20);
        assertEq(wrappedDividend.captainRightDenominator(1), 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 20);

        wrappedRoleAV1.setRoleLevelAndExp(mainId, 39, wrappedRoleAV1.expTable(38));
        assertEq(wrappedDividend.captainRightDenominator(1), 39);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 39);

        vm.prank(user1);
        uint256[] memory burn2_role_39_to_40 = new uint256[](2);
        burn2_role_39_to_40[0] = mainId + 2;
        burn2_role_39_to_40[1] = mainId + 3;
        wrappedRoleAV1.awake(mainId, burn2_role_39_to_40);
        assertEq(wrappedDividend.captainRightDenominator(1), 400);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 400);

        wrappedRoleAV1.setRoleLevelAndExp(mainId, 59, wrappedRoleAV1.expTable(58));
        assertEq(wrappedDividend.captainRightDenominator(1), 590);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 590);

        vm.prank(user1);
        uint256[] memory burn4_role_59_to_60 = new uint256[](4);
        burn4_role_59_to_60[0] = mainId + 4;
        burn4_role_59_to_60[1] = mainId + 5;
        burn4_role_59_to_60[2] = mainId + 6;
        burn4_role_59_to_60[3] = mainId + 7;
        wrappedRoleAV1.awake(mainId, burn4_role_59_to_60);
        assertEq(wrappedDividend.captainRightDenominator(1), 900);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 900);

        wrappedRoleAV1.setRoleLevelAndExp(mainId, 79, wrappedRoleAV1.expTable(78));
        assertEq(wrappedDividend.captainRightDenominator(1), 1185);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 1185);

        vm.prank(user1);
        uint256[] memory burn8_role_79_to_80 = new uint256[](8);
        burn8_role_79_to_80[0] = mainId + 8;
        burn8_role_79_to_80[1] = mainId + 9;
        burn8_role_79_to_80[2] = mainId + 10;
        burn8_role_79_to_80[3] = mainId + 11;
        burn8_role_79_to_80[4] = mainId + 12;
        burn8_role_79_to_80[5] = mainId + 13;
        burn8_role_79_to_80[6] = mainId + 14;
        burn8_role_79_to_80[7] = mainId + 15;
        wrappedRoleAV1.awake(mainId, burn8_role_79_to_80);
        assertEq(wrappedDividend.captainRightDenominator(1), 3200);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 3200);

        wrappedRoleAV1.setRoleLevelAndExp(mainId, 89, wrappedRoleAV1.expTable(88));
        assertEq(wrappedDividend.captainRightDenominator(1), 3560);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 3560);

        vm.prank(user1);
        uint256[] memory burn16_role_89_to_90 = new uint256[](16);
        for (uint256 i = 0; i < 16; i++) {
            burn16_role_89_to_90[i] = mainId + 16 + i;
        }
        wrappedRoleAV1.awake(mainId, burn16_role_89_to_90);
        assertEq(wrappedDividend.captainRightDenominator(1), 45000);
        assertEq(wrappedDividend.addressCaptainRight(user1, 1), 45000);

        assertEq(wrappedRoleAV1.getLevel(mainId), 90);
    }

    function testTransferCaptainRight() public {
        uint256 mainId = 1;
        wrappedRoleAV1.setRoleLevelAndExp(mainId, 60, wrappedRoleAV1.expTable(59));
        assertEq(wrappedDividend.captainRightDenominator(3), 900 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 900 + 20);
        vm.startPrank(user1);
        wrappedRoleAV1.transferFrom(user1, user2, mainId);
        assertEq(wrappedDividend.captainRightDenominator(3), 900 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 20);
        assertEq(wrappedDividend.addressCaptainRight(user2, 3), 900 + 20);
    }

    function testOnlyAllowPools() public {
        vm.expectRevert(NotAllowed.selector);
        wrappedDividend.claim(user1, 1);
        vm.prank(user1);
        vm.expectRevert(NotAllowed.selector);
        wrappedDividend.claim(user1, 1);
    }

    function testOnlyRoles() public {
        vm.expectRevert(NotAllowed.selector);
        wrappedDividend.addCaptainRight(user1, 1, 10000);
        vm.prank(user1);
        vm.expectRevert(NotAllowed.selector);
        wrappedDividend.setCaptainRight(user1, 1, 10000);
    }

    // TODO: loot & claim函数测试
}
