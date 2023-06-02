// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool, WhiteListUsed, InvalidSignature} from "../src/PFPDAOPool.sol";
import {PFPDAORole, Soulbound} from "../src/PFPDAORole.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract _PFPDAOPoolTest is PRBTest {
    using ECDSAUpgradeable for bytes32;
    using ECDSAUpgradeable for bytes;
    using StringsUpgradeable for string;
    using StringsUpgradeable for uint256;

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

    address signer;
    uint256 signerPrivateKey = 0xabcdf1234567890abcdef1234567890abcdef1234567890abcdef1234567890;
    address user1 = address(0x01);
    address user2 = address(0x02);
    address treasury = address(0x03);

    function setUp() public {
        signer = vm.addr(signerPrivateKey);

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
        wrappedPoolV1.setUpLegendaryId(upLegendaryId);
        wrappedPoolV1.setUpRareIds(upRareIds);
        wrappedPoolV1.setNormalLegendaryIds(normalLegendaryIds);
        wrappedPoolV1.setNormalRareIds(normalRareIds);
        wrappedPoolV1.setNormalCommonIds(normalCommonIds);

        wrappedEquipV1.addActivePool(address(proxyPool));
        wrappedRoleAV1.addActivePool(address(proxyPool));

        wrappedRoleAV1.setRoleName(1, "Linger");
        wrappedRoleAV1.setRoleName(2, "Kazuki");
        wrappedRoleAV1.setRoleName(3, "Mila");
        wrappedRoleAV1.setRoleName(4, "Mico");

        wrappedPoolV1.setTreasury(treasury);
        wrappedPoolV1.setSigner(signer);
        wrappedPoolV1.setActiveNonce(1);

        // vm mock user1 100 eth
        vm.deal(user1, 100 ether);

        // warp to 3 is bad lucky
        vm.warp(3);
    }

    function testSetUpPoolId() public {
        assertEq(wrappedPoolV1.upLegendaryId(), 1);
        assertEq(wrappedPoolV1.upRareIds(0), 2);
        assertEq(wrappedPoolV1.upRareIds(1), 3);
        assertEq(wrappedPoolV1.upRareIds(2), 4);
        vm.expectRevert();
        wrappedPoolV1.upRareIds(3);
        vm.expectRevert();
        assertEq(wrappedPoolV1.normalLegendaryIds(0), 0);
        vm.expectRevert();
        assertEq(wrappedPoolV1.normalRareIds(0), 0);
        assertEq(wrappedPoolV1.normalCommonIds(0), 0);

        // 第二期有8个角色，0是装备，1是legendary, 2-4是rare，5是legendary, 6-8是rare
        uint16 upLegendaryId = 5;
        uint16[] memory upRareIds = new uint16[](3);
        upRareIds[0] = 6;
        upRareIds[1] = 7;
        upRareIds[2] = 8;
        uint16[] memory normalLegendaryIds = new uint16[](1);
        normalLegendaryIds[0] = 1;
        uint16[] memory normalRareIds = new uint16[](3);
        normalRareIds[0] = 2;
        normalRareIds[1] = 3;
        normalRareIds[2] = 4;
        uint16[] memory normalCommonIds = new uint16[](1);
        normalCommonIds[0] = 0;
        wrappedPoolV1.setUpLegendaryId(upLegendaryId);
        wrappedPoolV1.setUpRareIds(upRareIds);
        wrappedPoolV1.setNormalLegendaryIds(normalLegendaryIds);
        wrappedPoolV1.setNormalRareIds(normalRareIds);
        wrappedPoolV1.setNormalCommonIds(normalCommonIds);

        assertEq(wrappedPoolV1.upLegendaryId(), 5);
        assertEq(wrappedPoolV1.upRareIds(0), 6);
        assertEq(wrappedPoolV1.upRareIds(1), 7);
        assertEq(wrappedPoolV1.upRareIds(2), 8);
        vm.expectRevert();
        wrappedPoolV1.upRareIds(3);
        assertEq(wrappedPoolV1.normalLegendaryIds(0), 1);
        assertEq(wrappedPoolV1.normalRareIds(0), 2);
        assertEq(wrappedPoolV1.normalRareIds(1), 3);
        assertEq(wrappedPoolV1.normalRareIds(2), 4);
        assertEq(wrappedPoolV1.normalCommonIds(0), 0);
    }

    function testLoot1_newUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot1{value: 2.8 ether}();
        assertEq(wrappedEquipV1.balanceOf(user1) + wrappedRoleAV1.balanceOf(user1), 1);
        assertEq(wrappedEquipV1.balanceOf(1), 1);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
    }

    function testLoot10_newUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        // will have 9 equip and 1 role
        assertEq(wrappedEquipV1.balanceOf(1), 9);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
        assertEq(wrappedRoleAV1.balanceOf(1), 1);
        assertEq(wrappedRoleAV1.balanceOf(user1), 1);
    }

    function testLoot1_oldUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));
        wrappedPoolV1.loot1{value: 2.8 ether}(captainId, 1); // first nftid will 1
        uint32 exp = wrappedRoleAV1.getExp(wrappedRoleAV1.slotOf(1));
        assertEq(exp, 2);
    }

    function testLoot10_oldUser(uint256 timestamp) public {
        vm.warp(timestamp);
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        uint256 roleSlot = wrappedRoleAV1.slotOf(1);
        uint16 captainId = wrappedRoleAV1.getRoleId(roleSlot);
        (uint256 newSlot,) = wrappedRoleAV1.addExp(roleSlot, 20);
        uint32 expExpect = wrappedRoleAV1.getExp(newSlot);
        uint8 levelExpect = wrappedRoleAV1.getLevel(newSlot);
        assertEq(expExpect, 10);
        assertEq(levelExpect, 2);
        wrappedPoolV1.loot10{value: 22 ether}(captainId, 1); // first nftid will 1
        uint256 roleSlotAfterlevelUp = wrappedRoleAV1.slotOf(1);
        uint32 expActual = wrappedRoleAV1.getExp(roleSlotAfterlevelUp);
        uint8 levelActual = wrappedRoleAV1.getLevel(roleSlotAfterlevelUp);
        assertEq(expActual, 10);
        assertEq(levelActual, 2);
    }

    event LootResult(address indexed user, uint256 slots, uint8 balance);

    function testLootResultEvent_1() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LootResult(user1, 1099511627776, 1);
        wrappedPoolV1.loot1{value: 2.8 ether}(captainId, 1);
    }

    function testLootResultEvent_2() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LootResult(user1, 1099511627776, 9);
        emit LootResult(user1, 929663955283932409837387776, 1);
        wrappedPoolV1.loot10{value: 2.8 ether}(captainId, 1);
    }

    event LevelResult(uint256 indexed nftId, uint8 newLevel, uint32 newExp);

    function testLevelResultEvent() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        uint16 captainId = wrappedRoleAV1.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LevelResult(1, 2, 10);
        wrappedPoolV1.loot10{value: 22 ether}(captainId, 1);
    }

    event GuarResult(address indexed user, uint8 newSSGuar, uint8 newSSSGuar, bool isUpSSS);

    function testGuarResultEvent_1() public {
        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true);
        emit GuarResult(user1, 1, 1, false);
        wrappedPoolV1.loot1{value: 2.8 ether}();
    }

    function testGuarResultEvent_2() public {
        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true);
        emit GuarResult(user1, 7, 10, false);
        wrappedPoolV1.loot10{value: 22 ether}();
    }

    function testGetGuarResult() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        (uint8 newSSGuar, uint8 newSSSGuar, bool isUpSSS) = wrappedPoolV1.getGuarInfo(user1);
        assertEq(newSSGuar, 7);
        assertEq(newSSSGuar, 10);
        assertEq(isUpSSS, false);
    }

    function testWhitelistLoot1() public {
        // Set the active nonce to 1
        wrappedPoolV1.setActiveNonce(1);

        // server sign the messageHash
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPrivateKey, keccak256(abi.encodePacked(user1, uint8(10), uint8(1))).toEthSignedMessageHash()); // user1 have 10 freeloot at batch 1
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(user1);
        wrappedPoolV1.whitelistLoot(10, signature);

        assertEq(wrappedEquipV1.balanceOf(1), 9);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
        assertEq(wrappedRoleAV1.balanceOf(1), 1);
        assertEq(wrappedRoleAV1.balanceOf(user1), 1);

        // mint with same signature should revert
        vm.expectRevert(abi.encodeWithSelector(WhiteListUsed.selector, 1));
        wrappedPoolV1.whitelistLoot(10, signature);

        // test view
        assertEq(wrappedPoolV1.isWhitelistLooted(user1), 1);
        assertEq(wrappedPoolV1.isWhitelistLooted(user2), 0);
    }

    function testWhitelistLoot2() public {
        wrappedPoolV1.setActiveNonce(2);

        // server sign the messageHash
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPrivateKey, keccak256(abi.encodePacked(user1, uint8(10), uint8(1))).toEthSignedMessageHash()); // user1 have 10 freeloot at batch 1
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(user1);
        vm.expectRevert(InvalidSignature.selector);
        wrappedPoolV1.whitelistLoot(10, signature);
    }

    function testWhitelistLoot3() public {
        wrappedPoolV1.setActiveNonce(1);

        // server sign the messageHash
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPrivateKey, keccak256(abi.encodePacked(user1, uint8(10), uint8(1))).toEthSignedMessageHash()); // user1 have 10 freeloot at batch 1
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(user2);
        vm.expectRevert(InvalidSignature.selector);
        wrappedPoolV1.whitelistLoot(10, signature);
    }

    function testWhitelistLoot4() public {
        wrappedPoolV1.setActiveNonce(1);

        // server sign the messageHash
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPrivateKey, keccak256(abi.encodePacked(user1, uint8(10), uint8(1))).toEthSignedMessageHash()); // user1 have 10 freeloot at batch 1
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(user1);
        vm.expectRevert(InvalidSignature.selector);
        wrappedPoolV1.whitelistLoot(5, signature); // have 10 freeloot but only use 5
    }

    using SignatureCheckerUpgradeable for address;

    function testWhitelistLoot5() public {
        address user = address(0x49E53Fb3d5bf1532fEBAD88a1979E33A94844d1d);
        uint8 times = 1;
        uint8 nonce = 1;
        uint256 signer_pk = vm.envUint("SIGNER_PK");
        bytes memory data = abi.encodePacked(user, times, nonce);
        bytes32 messageHash = keccak256(data);
        bytes32 signedMessage = messageHash.toEthSignedMessageHash();
        // server sign the messageHash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer_pk, signedMessage); // user1 have 10 freeloot at batch 1
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        vm.expectRevert(InvalidSignature.selector);
        wrappedPoolV1.whitelistLoot(1, signature);
    }

    function testWhitelistLoot6() public {
        wrappedPoolV1.setActiveNonce(1);

        // server sign the messageHash
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPrivateKey, keccak256(abi.encodePacked(user1, uint8(2), uint8(1))).toEthSignedMessageHash()); // user1 have 2 freeloot at batch 1
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startPrank(user1);
        wrappedPoolV1.whitelistLoot(2, signature);
    }

    // test withdraw
    function testWithdraw() public {
        vm.prank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        wrappedPoolV1.withdraw();
        assertEq(address(treasury).balance, 22 ether);
    }
}
