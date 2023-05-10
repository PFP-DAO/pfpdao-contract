// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract _PFPDAOPoolTest is PRBTest {
    PFPDAOPool implementationPoolV1;
    PFPDAOEquipment implementationEquipV1;
    PFPDAORole implementationRoleAV1;
    PFPDAORole implementationRoleBV1;

    UUPSProxy proxyPool;
    UUPSProxy proxyEquip;
    UUPSProxy proxyRoleA;
    UUPSProxy proxyRoleB;

    PFPDAOPool wrappedPoolV1;
    PFPDAOEquipment wrappedEquipV1;
    PFPDAORole wrappedRoleAV1;
    PFPDAORole wrappedRoleBV1;

    address user1 = address(0x01);

    function setUp() public {
        implementationPoolV1 = new PFPDAOPool();
        implementationEquipV1 = new PFPDAOEquipment();
        implementationRoleAV1 = new PFPDAORole();
        implementationRoleBV1 = new PFPDAORole();

        // 部署代理合约并将其指向实现合约，这个是ERC1967Proxy
        proxyPool = new UUPSProxy(address(implementationPoolV1), "");
        proxyEquip = new UUPSProxy(address(implementationEquipV1), "");
        proxyRoleA = new UUPSProxy(address(implementationRoleAV1), "");
        proxyRoleB = new UUPSProxy(address(implementationRoleBV1), "");

        // 将代理合约包装成ABI，以支持更容易的调用
        wrappedPoolV1 = PFPDAOPool(address(proxyPool));
        wrappedEquipV1 = PFPDAOEquipment(address(proxyEquip));
        wrappedRoleAV1 = PFPDAORole(address(proxyRoleA));
        wrappedRoleBV1 = PFPDAORole(address(proxyRoleB));

        // 初始化合约
        wrappedPoolV1.initialize(address(proxyEquip), address(proxyRoleA));
        wrappedEquipV1.initialize();
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");
        wrappedRoleBV1.initialize("PFPDAORoleB", "PFPRB");

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
        wrappedPoolV1.setPoolRoleIds(upLegendaryId, upRareIds, normalLegendaryIds, normalRareIds, normalCommonIds);
        wrappedEquipV1.addActivePool(address(proxyPool));
        wrappedRoleAV1.addActivePool(address(proxyPool));

        // vm mock user1 100 eth
        vm.deal(user1, 100 ether);

        // warp to 3 is bad lucky
        vm.warp(3);
    }

    function testLoot1_newUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot1{value: 0.001 ether}();
        assertEq(wrappedEquipV1.balanceOf(user1) + wrappedRoleAV1.balanceOf(user1), 1);
        assertEq(wrappedEquipV1.balanceOf(1), 1);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
    }

    function testLoot10_newUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 0.01 ether}();
        // will have 9 equip and 1 role
        assertEq(wrappedEquipV1.balanceOf(1), 9);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
        assertEq(wrappedRoleAV1.balanceOf(1), 1);
        assertEq(wrappedRoleAV1.balanceOf(user1), 1);
    }

    function testLoot1_oldUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 0.01 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));
        wrappedPoolV1.loot1{value: 0.001 ether}(captainId, 1); // first nftid will 1
        uint32 exp = wrappedRoleAV1.getExp(wrappedRoleAV1.slotOf(1));
        assertEq(exp, 2);
    }

    function testLoot10_oldUser(uint256 timestamp) public {
        vm.warp(timestamp);
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 0.01 ether}();
        uint256 roleSlot = wrappedRoleAV1.slotOf(1);
        uint16 captainId = wrappedRoleAV1.getRoleId(roleSlot);
        (uint256 newSlot,) = wrappedRoleAV1.addExp(roleSlot, 20);
        uint32 expExpect = wrappedRoleAV1.getExp(newSlot);
        uint8 levelExpect = wrappedRoleAV1.getLevel(newSlot);
        assertEq(expExpect, 10);
        assertEq(levelExpect, 2);
        wrappedPoolV1.loot10{value: 0.01 ether}(captainId, 1); // first nftid will 1
        uint256 roleSlotAfterlevelUp = wrappedRoleAV1.slotOf(1);
        uint32 expActual = wrappedRoleAV1.getExp(roleSlotAfterlevelUp);
        uint8 levelActual = wrappedRoleAV1.getLevel(roleSlotAfterlevelUp);
        assertEq(expActual, 10);
        assertEq(levelActual, 2);
    }

    event LootResult(address indexed user, uint256 slots, uint8 balance);

    function testLootResultEvent_1() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 0.01 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LootResult(user1, 1099511627776, 1);
        wrappedPoolV1.loot1{value: 0.001 ether}(captainId, 1);
    }

    function testLootResultEvent_2() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 0.01 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LootResult(user1, 1099511627776, 9);
        emit LootResult(user1, 929663955283932409837387776, 1);
        wrappedPoolV1.loot10{value: 0.001 ether}(captainId, 1);
    }

    event LevelResult(uint256 indexed nftId, uint8 newLevel, uint32 newExp);

    function testLevelResultEvent() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 0.01 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LevelResult(1, 2, 10);
        wrappedPoolV1.loot10{value: 0.01 ether}(captainId, 1);
    }

    event GuarResult(address indexed user, uint8 newSSGuar, uint8 newSSSGuar, bool isUpSSS);

    function testGuarResultEvent_1() public {
        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true);
        emit GuarResult(user1, 1, 1, false);
        wrappedPoolV1.loot1{value: 0.001 ether}();
    }

    function testGuarResultEvent_2() public {
        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true);
        emit GuarResult(user1, 7, 10, false);
        wrappedPoolV1.loot10{value: 0.01 ether}();
    }
}
