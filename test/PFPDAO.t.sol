// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import {PFPDAOEquipment, NotBurner} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAOEquipMetadataDescriptor} from "../src/PFPDAOEquipMetadataDescriptor.sol";
import {PFPDAORole, Soulbound, InvalidSlot, NotAllowed, NotOwner} from "../src/PFPDAORole.sol";
import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";
import {Dividend} from "../src/Dividend.sol";
import {FiatToken} from "../src/FiatToken.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract _PFPDAOTest is PRBTest {
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

        // vm mock user1 100 eth
        vm.deal(user1, 100 ether);

        // warp to 3 is bad lucky
        vm.warp(3);
    }

    function _loot10GetARole() private {
        vm.prank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
    }

    function testCanInitialize() public {
        // 测试初始化是否成功
        assertEq(wrappedEquipV1.symbol(), "PFPE");
        assertEq(wrappedRoleAV1.symbol(), "PFPRA");
        assertEq(wrappedRoleAV1.name(), "PFPDAORoleA");
        assertEq(wrappedRoleBV1.symbol(), "PFPRB");
    }

    function testRoleName() public {
        assertEq(wrappedRoleAV1.roldIdToName(1), "Linger");
        assertEq(wrappedRoleAV1.roldIdToName(2), "Kazuki");
        assertEq(wrappedRoleAV1.roldIdToName(3), "Mila");
        assertEq(wrappedRoleAV1.roldIdToName(4), "Mico");
    }

    // Test Role function
    function testGetSlotProps() public {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 0, 1023, 1);
        assertEq(wrappedRoleAV1.getRoleId(tempSlot), 1);
        assertEq(wrappedRoleAV1.getRarity(tempSlot), 0);
        assertEq(wrappedRoleAV1.getVariant(tempSlot), 1023);
        assertEq(wrappedRoleAV1.getStyle(tempSlot), 1);
    }

    function testActivePool() public {
        wrappedRoleAV1.addActivePool(address(wrappedPoolV1));
        assertTrue(wrappedRoleAV1.isActivePool(address(wrappedPoolV1)));
        wrappedRoleAV1.removeActivePool(address(wrappedPoolV1));
        assertFalse(wrappedRoleAV1.isActivePool(address(wrappedPoolV1)));
    }

    function testSoulbound() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();

        vm.expectRevert(Soulbound.selector);
        wrappedRoleAV1.safeTransferFrom(user1, user2, 1);

        vm.expectRevert(Soulbound.selector);
        wrappedRoleAV1.transferFrom(user1, user2, 1);

        // vm.expectRevert(Soulbound.selector);
        wrappedEquipV1.safeTransferFrom(user1, user2, 1);

        // vm.expectRevert(Soulbound.selector);
        // wrappedEquipV1.transferFrom(user1, address(this), 1);

        // vm.expectRevert(Soulbound.selector);
        // wrappedEquipV1.transferFrom(1, address(this), 9);
    }

    function testTokenURI() public {
        _loot10GetARole();

        string memory roleUri = wrappedRoleAV1.tokenURI(1);
        assertEq(roleUri, "https://pfpdao-0.4everland.store/metadata/4/V1_0/role_4_V1_0_1_Mico.json");

        vm.deal(user2, 22 ether);
        vm.prank(user2);
        vm.warp(6);
        wrappedPoolV1.loot10{value: 22 ether}();
        string memory roleUri2 = wrappedRoleAV1.tokenURI(2); // This will be Mico
        assertEq(roleUri2, "https://pfpdao-0.4everland.store/metadata/4/V1_0/role_4_V1_0_2_Mico.json");
    }

    // function testAirdrop() public {
    //     // Call the airdrop function with an array of addresses and a slot number
    //     address[] memory recipients = new address[](2);
    //     recipients[0] = address(0x123);
    //     recipients[1] = address(0x456);
    //     wrappedRoleAV1.airdrop(recipients, 1, 1, 1);

    //     // Check that the recipients received the tokens
    //     uint256 balance0 = wrappedRoleAV1.balanceOf(recipients[0]);
    //     uint256 balance1 = wrappedRoleAV1.balanceOf(recipients[1]);
    //     assertEq(balance0, 1);
    //     assertEq(balance1, 1);

    //     // Check that the slot number is correct
    //     uint256 recipient1RoleSlot = wrappedRoleAV1.slotOf(1);
    //     uint32 variant1 = wrappedRoleAV1.getVariant(recipient1RoleSlot);
    //     assertEq(variant1, 1);
    //     assertEq(wrappedRoleAV1.getRoleId(recipient1RoleSlot), 1);
    //     uint256 recipient2RoleSlot = wrappedRoleAV1.slotOf(2);
    //     uint32 variant2 = wrappedRoleAV1.getVariant(recipient2RoleSlot);
    //     assertEq(variant2, 2);
    //     assertEq(wrappedRoleAV1.getRoleId(recipient2RoleSlot), 1);
    //     vm.expectRevert(InvalidSlot.selector);
    //     wrappedRoleAV1.airdrop(recipients, 1, 1, 60);

    //     vm.expectRevert(InvalidSlot.selector);
    //     wrappedRoleAV1.airdrop(recipients, 5, 1, 1);
    // }

    function testEquipMint() public {
        vm.startPrank(user1);
        vm.expectRevert("only active pool can mint");
        wrappedEquipV1.mint(user1, 1, 1);
    }

    function testLevelUp() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        vm.expectRevert(NotAllowed.selector);
        wrappedRoleAV1.levelUpWhenLoot(1, 1);
    }

    function setAllowBurners() internal {
        address[] memory allowedBurners = new address[](1);
        allowedBurners[0] = address(wrappedRoleAV1);
        wrappedEquipV1.updateAllowedBurners(allowedBurners);
    }

    function testAllowBurners() public {
        setAllowBurners();
        assertEq(wrappedEquipV1.getAllowedBurner(0), address(wrappedRoleAV1));
    }

    function testBurn() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        // if no allowed burner, revert
        vm.expectRevert(abi.encodeWithSelector(NotBurner.selector, user1));
        wrappedEquipV1.burn(1);
    }

    function testLevelUpByBurnEquipmentSingle() public {
        setAllowBurners();

        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();

        // user should have 1 role and 1 equip, equip balance is 9
        assertEq(wrappedRoleAV1.balanceOf(user1), 1);
        assertEq(wrappedEquipV1.balanceOf(user1), 1);
        assertEq(wrappedEquipV1.balanceOf(1), 9);

        uint256[] memory equipmentIds = new uint256[](1);
        equipmentIds[0] = 1;
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipmentIds);

        // roleA nft 1 should have 72 exp
        assertEq(wrappedRoleAV1.getExp(1), 11);
        assertEq(wrappedRoleAV1.getLevel(1), 6);
    }

    function testLevelUpByBurnEquipmentBatch() public {
        setAllowBurners();

        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}();
        wrappedPoolV1.loot10{value: 22 ether}();

        // user should have 2 role and 2 equip, equip balance is 9, 9
        assertEq(wrappedRoleAV1.balanceOf(user1), 2);
        assertEq(wrappedEquipV1.balanceOf(user1), 2);
        assertEq(wrappedEquipV1.balanceOf(1), 9);
        assertEq(wrappedEquipV1.balanceOf(2), 9);

        uint256[] memory equipmentIds = new uint256[](2);
        equipmentIds[0] = 1;
        equipmentIds[1] = 2;
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipmentIds);

        // roleA nft 1 should have 144 exp
        assertEq(wrappedRoleAV1.getExp(1), 9);
        assertEq(wrappedRoleAV1.getLevel(1), 10);

        // roleA nft 2 should have 0 exp
        assertEq(wrappedRoleAV1.getExp(2), 0);
        assertEq(wrappedRoleAV1.getLevel(2), 1);

        // equip nft 1 and 2 should be burned
        assertEq(wrappedEquipV1.balanceOf(user1), 0);
        vm.expectRevert("ERC3525: invalid token ID");
        wrappedEquipV1.balanceOf(1);
        vm.expectRevert("ERC3525: invalid token ID");
        wrappedEquipV1.balanceOf(2);
        assertEq(wrappedEquipV1.totalSupply(), 0);
    }

    function testLevelUpByBurnEquipmentError() public {
        setAllowBurners();
        // test equipmentIds is empty
        _loot10GetARole();

        vm.deal(user2, 22 ether);
        vm.prank(user2);
        vm.warp(6);
        wrappedPoolV1.loot10{value: 22 ether}();

        // equipmentIds is empty
        uint256[] memory equipmentIdsEmpty = new uint256[](0);
        vm.expectRevert("EquipmentIds is empty");
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipmentIdsEmpty);

        uint256[] memory equipmentIdsUser1 = new uint256[](1);
        equipmentIdsUser1[0] = 1;

        // user2 levelup use user1's equipment
        vm.prank(user2);
        vm.expectRevert(NotOwner.selector);
        wrappedRoleAV1.levelUpByBurnEquipments(2, equipmentIdsUser1);

        // user1 levelup NFT belong to user2
        vm.prank(user1);
        vm.expectRevert(NotOwner.selector);
        wrappedRoleAV1.levelUpByBurnEquipments(2, equipmentIdsUser1);

        // user1 levelup NFT not exist
        vm.prank(user1);
        vm.expectRevert("ERC3525: invalid token ID");
        wrappedRoleAV1.levelUpByBurnEquipments(100, equipmentIdsUser1);

        // user1 levelup use burned equipments
        vm.prank(user1);
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipmentIdsUser1);
        vm.expectRevert(NotOwner.selector);
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipmentIdsUser1);
    }

    function testLevelUpByBurnCustom1() public {
        setAllowBurners();

        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        wrappedRoleAV1.airdrop(recipients, 3, 1);

        vm.startPrank(user1);
        wrappedPoolV1.loot1{value: 2.8 ether}();
        wrappedPoolV1.loot1{value: 2.8 ether}();
        wrappedPoolV1.loot1{value: 2.8 ether}();
        wrappedPoolV1.loot1{value: 2.8 ether}();
        console2.log(wrappedEquipV1.balanceOf(user1));

        uint256[] memory equipmentIds = new uint256[](4);
        equipmentIds[0] = 1;
        equipmentIds[1] = 4;
        equipmentIds[2] = 3;
        equipmentIds[3] = 2;
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipmentIds);

        console2.log(wrappedRoleAV1.getExp(1));
        console2.log(wrappedRoleAV1.getLevel(1));
        // roleA nft 1 should have 32 exp
        assertEq(wrappedRoleAV1.getExp(1), 11);
        assertEq(wrappedRoleAV1.getLevel(1), 3);
    }

    // function testReachLimitLevel() public {
    //     _loot10GetARole();

    //     assertFalse(wrappedRoleAV1.reachLimitLevel(1));

    //     wrappedRoleAV1.setRoleExp(1, 19, 56);
    //     assertTrue(wrappedRoleAV1.reachLimitLevel(1));
    // }

    function testGenerateSlotWhenAwake() public {
        uint256 oldSlot = wrappedRoleAV1.generateSlot(2, 1, 88, 1); // 88 variant's roldId 1 style1
        uint256 newSlot = wrappedRoleAV1.generateSlotWhenAwake(oldSlot, 10); // 10 variant's roldId 1 style2
        assertEq(wrappedRoleAV1.getRoleId(newSlot), 2);
        assertEq(wrappedRoleAV1.getRarity(newSlot), 1);
        assertEq(wrappedRoleAV1.getStyle(newSlot), 2);
        assertEq(wrappedRoleAV1.getVariant(newSlot), 10);
        uint32[] memory oldVariants = wrappedRoleAV1.getVariants(newSlot);

        assertEq(oldVariants[0], 88);
        assertEq(oldVariants.length, 1);

        uint256 newSlot2 = wrappedRoleAV1.generateSlotWhenAwake(newSlot, 3);
        assertEq(wrappedRoleAV1.getRoleId(newSlot2), 2);
        assertEq(wrappedRoleAV1.getRarity(newSlot2), 1);
        assertEq(wrappedRoleAV1.getStyle(newSlot2), 3);
        assertEq(wrappedRoleAV1.getVariant(newSlot2), 3);
        uint32[] memory oldVariants2 = wrappedRoleAV1.getVariants(newSlot2);

        assertEq(oldVariants2[0], 88);
        assertEq(oldVariants2[1], 10);
        assertEq(oldVariants2.length, 2);
    }

    function testEquipUri() public {
        _loot10GetARole();
        string memory equipUri = wrappedEquipV1.tokenURI(1);
        console2.log("equipUri: %s", equipUri);
        assertEq(
            equipUri,
            "data:application/json;base64,eyJuYW1lIjoiVGhlIFBvd2VyIG9mIENoYW9zICMxIiwiZGVzY3JpcHRpb24iOiJQRlBEQU8gZXF1aXBtZW50LCBhZGQgZXhwZXJpZW5jZSBwb2ludHMgdG8gYW55IHJvbGUgd2hlbiBidXJuZWQuIiwiaW1hZ2UiOiJodHRwczovL3BmcGRhby0wLjRldmVybGFuZC5zdG9yZS9lcXVpcG1lbnQvYXZhdGFyLWVxdWlwLmpwZyIsImJhbGFuY2UiOiI5Iiwic2xvdCI6IjEwOTk1MTE2Mjc3NzYiLCJwcm9wZXJ0aWVzIjp7ImJhbGFuY2UiOjl9fQ=="
        );
    }
}
