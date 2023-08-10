// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool, WhiteListUsed, InvalidSignature} from "../src/PFPDAOPool.sol";
import {PFPDAOEquipMetadataDescriptor} from "../src/PFPDAOEquipMetadataDescriptor.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";
import {Soulbound} from "../src/PFPDAO.sol";
import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";
import {FiatToken} from "../src/FiatToken.sol";
import {Utils} from "../src/libraries/Utils.sol";
import {Dividend} from "../src/Dividend.sol";

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
    address user1 = address(0x01);
    address user2 = address(0x02);
    address treasury = address(0x03);

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
        // wrappedRoleBV1.setStyleVariantManager(address(proxyStyleManager));
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
        wrappedPoolV1.setPriceLootOne(2800000);
        wrappedPoolV1.setPriceLootTen(22000000);

        wrappedEquipV1.addActivePool(address(proxyPool));
        wrappedRoleAV1.addActivePool(address(proxyPool));

        wrappedRoleAV1.setRoleName(1, "Linger");
        wrappedRoleAV1.setRoleName(2, "Kazuki");
        wrappedRoleAV1.setRoleName(3, "Mila");
        wrappedRoleAV1.setRoleName(4, "Mico");

        wrappedPoolV1.setTreasury(treasury);
        wrappedPoolV1.setSigner(signer);
        wrappedPoolV1.setDividend(address(proxyDividend));
        wrappedPoolV1.setUseNewPrice(true);
        wrappedPoolV1.setUSDC(address(wrappedUSDC));

        wrappedRoleAV1.setEquipmentContract(address(proxyEquip));

        wrappedEquipV1.setMetadataDescriptor(address(proxyMetadataDescriptor));

        // vm mock user1 100 eth and 100 usdc
        vm.deal(user1, 100 ether);
        wrappedUSDC.mint(user1, 100000000);

        // warp to 3 is bad lucky
        vm.warp(3);
    }

    function testSetUpPoolId() public {
        assertEq(wrappedPoolV1.upSSSId(), 1);
        assertEq(wrappedPoolV1.upSSIds(0), 2);
        assertEq(wrappedPoolV1.upSSIds(1), 3);
        assertEq(wrappedPoolV1.upSSIds(2), 4);
        vm.expectRevert();
        wrappedPoolV1.upSSIds(3);
        vm.expectRevert();
        assertEq(wrappedPoolV1.nSSSIds(0), 0);
        vm.expectRevert();
        assertEq(wrappedPoolV1.nSSIds(0), 0);
        assertEq(wrappedPoolV1.nSIds(0), 0);

        // 第二期有8个角色，0是装备，1是legendary, 2-4是rare，5是legendary, 6-8是rare
        uint16 upSSSId = 5;
        uint16[] memory upSSIds = new uint16[](3);
        upSSIds[0] = 6;
        upSSIds[1] = 7;
        upSSIds[2] = 8;
        uint16[] memory nSSSIds = new uint16[](1);
        nSSSIds[0] = 1;
        uint16[] memory nSSIds = new uint16[](3);
        nSSIds[0] = 2;
        nSSIds[1] = 3;
        nSSIds[2] = 4;
        uint16[] memory nSIds = new uint16[](1);
        nSIds[0] = 0;
        wrappedPoolV1.setupSSSId(upSSSId);
        wrappedPoolV1.setupSSIds(upSSIds);
        wrappedPoolV1.setnSSSIds(nSSSIds);
        wrappedPoolV1.setnSSIds(nSSIds);
        wrappedPoolV1.setnSIds(nSIds);

        assertEq(wrappedPoolV1.upSSSId(), 5);
        assertEq(wrappedPoolV1.upSSIds(0), 6);
        assertEq(wrappedPoolV1.upSSIds(1), 7);
        assertEq(wrappedPoolV1.upSSIds(2), 8);
        vm.expectRevert();
        wrappedPoolV1.upSSIds(3);
        assertEq(wrappedPoolV1.nSSSIds(0), 1);
        assertEq(wrappedPoolV1.nSSIds(0), 2);
        assertEq(wrappedPoolV1.nSSIds(1), 3);
        assertEq(wrappedPoolV1.nSSIds(2), 4);
        assertEq(wrappedPoolV1.nSIds(0), 0);
    }

    function testLoot1_newUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot1{value: 2.8 ether}(false);
        assertEq(wrappedEquipV1.balanceOf(user1) + wrappedRoleAV1.balanceOf(user1), 1);
        assertEq(wrappedEquipV1.balanceOf(1), 1);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
    }

    function testFuzz_Loot10(uint256 height_) public {
        vm.warp(height_);
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
    }

    function testLoot10_newUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        // will have 9 equip and 1 role
        assertEq(wrappedEquipV1.balanceOf(1), 9);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
        assertEq(wrappedRoleAV1.balanceOf(1), 1);
        assertEq(wrappedRoleAV1.balanceOf(user1), 1);
    }

    function testLoot1_oldUser() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        uint16 captainId = Utils.getRoleId(wrappedRoleAV1.slotOf(1));
        wrappedPoolV1.loot1{value: 2.8 ether}(captainId, 1, false); // first nftid will 1
        uint32 exp = wrappedRoleAV1.getExp(1);
        assertEq(exp, 2);
    }

    function testLoot10_oldUser(uint256 timestamp) public {
        vm.warp(timestamp);
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        uint256 roleSlot = wrappedRoleAV1.slotOf(1);
        uint16 captainId = Utils.getRoleId(roleSlot);
        uint32 expExpect = wrappedRoleAV1.getExp(1);
        uint8 levelExpect = wrappedRoleAV1.getLevel(1);
        assertEq(expExpect, 0);
        assertEq(levelExpect, 1);

        wrappedPoolV1.loot10{value: 22 ether}(captainId, 1, false); // first nftid will 1
        uint32 expActual = wrappedRoleAV1.getExp(1);
        uint8 levelActual = wrappedRoleAV1.getLevel(1);
        assertEq(expActual, 10);
        assertEq(levelActual, 2);
    }

    event LootResult(address indexed user, uint256 slots, uint8 balance);

    function testLootResultEvent_1() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        uint16 captainId = Utils.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LootResult(user1, 1099511627776, 1);
        wrappedPoolV1.loot1{value: 2.8 ether}(captainId, 1, false);
    }

    function testLootResultEvent_2() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        uint16 captainId = Utils.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LootResult(user1, 1099511627776, 9);
        emit LootResult(user1, 929663955283932409837387776, 1);
        wrappedPoolV1.loot10{value: 22 ether}(captainId, 1, false);
    }

    event LevelResult(uint256 indexed nftId, uint8 newLevel, uint32 newExp);

    function testLevelResultEvent() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        uint16 captainId = Utils.getRoleId(wrappedRoleAV1.slotOf(1));

        vm.expectEmit(true, false, false, true);
        emit LevelResult(1, 2, 10);
        wrappedPoolV1.loot10{value: 22 ether}(captainId, 1, false);
    }

    event GuarResult(address indexed user, uint8 newSSGuar, uint8 newSSSGuar, bool isUpSSS);

    function testGuarResultEvent_1() public {
        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true);
        emit GuarResult(user1, 1, 1, false);
        wrappedPoolV1.loot1{value: 2.8 ether}(false);
    }

    function testGuarResultEvent_2() public {
        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true);
        emit GuarResult(user1, 7, 10, false);
        wrappedPoolV1.loot10{value: 22 ether}(false);
    }

    function testGetGuarResult() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        (uint8 newSSGuar, uint8 newSSSGuar, bool isUpSSS) = wrappedPoolV1.getGuarInfo(user1);
        assertEq(newSSGuar, 7);
        assertEq(newSSSGuar, 10);
        assertEq(isUpSSS, false);
    }

    event PayLoot(address indexed user, uint256 amount, bool usdc, uint16 captainId);

    function testPayLootEvent() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        uint16 captainId = Utils.getRoleId(wrappedRoleAV1.slotOf(1));
        vm.expectEmit(true, true, false, true);
        emit PayLoot(user1, 2800000000000000000, false, captainId);
        // pay matic with captain
        wrappedPoolV1.loot1{value: 2.8 ether}(captainId, 1, false);

        wrappedUSDC.approve(address(wrappedPoolV1), 56 * 10 ** 5);
        vm.expectEmit(true, true, false, true);
        emit PayLoot(user1, 2800000, true, captainId);
        // pay usdc with captain
        wrappedPoolV1.loot1(captainId, 1, true);

        vm.expectEmit(true, true, false, true);
        emit PayLoot(user1, 2800000, true, wrappedPoolV1.upSSSId());
        // pay usdc with no captain
        wrappedPoolV1.loot1(true);

        vm.expectEmit(true, true, false, true);
        emit PayLoot(user1, 2800000000000000000, false, wrappedPoolV1.upSSSId());
        // pay matic with no captain
        wrappedPoolV1.loot1{value: 2.8 ether}(false);
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
        wrappedPoolV1.setActiveNonce(1);
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
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.withdraw();
        assertEq(address(treasury).balance, 22 ether);
    }

    function testStyleVariantManager() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.loot10{value: 22 ether}(false);

        assertEq(wrappedStyleManagerV1.viewLastVariant(2, 1), 1);

        assertEq(wrappedRoleAV1.tokenURI(1), wrappedRoleAV1.tokenURI(2));
        assertEq(wrappedRoleAV1.tokenURI(2), wrappedRoleAV1.tokenURI(3));
        assertEq(wrappedRoleAV1.tokenURI(3), wrappedRoleAV1.tokenURI(4));
        assertEq(
            keccak256(abi.encode("https://pfpdao-0.4everland.store/metadata/2/V1_0/role_2_V1_0_1_Kazuki.json")),
            keccak256(abi.encode(wrappedRoleAV1.tokenURI(4)))
        );

        assertEq(4, wrappedRoleAV1.balanceOf(user1));

        vm.warp(10);
        vm.deal(user2, 22 ether);
        vm.startPrank(user2);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        assertEq(
            keccak256(abi.encode("https://pfpdao-0.4everland.store/metadata/2/V1_0/role_2_V1_0_2_Kazuki.json")),
            keccak256(abi.encode(wrappedRoleAV1.tokenURI(5)))
        );

        assertEq(wrappedStyleManagerV1.viewLastVariant(2, 1), 2);
        assertEq(wrappedStyleManagerV1.viewRoleAwakenVariant(user1, 2, 1), 1);
        assertEq(wrappedStyleManagerV1.viewRoleAwakenVariant(user2, 2, 1), 2);
        assertEq(wrappedStyleManagerV1.viewRoleAwakenVariant(treasury, 2, 1), 0);
    }
}
