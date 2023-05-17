// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract _PFPDAOTest is PRBTest {
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

    address admin = address(0x01);
    address user1 = address(0x02);

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
        console2.log("wrappedEquipV1 owner", wrappedEquipV1.owner());
        wrappedRoleAV1 = PFPDAORole(address(proxyRoleA));
        wrappedRoleBV1 = PFPDAORole(address(proxyRoleB));

        // 初始化合约
        wrappedEquipV1.initialize();
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");
        wrappedRoleBV1.initialize("PFPDAORoleB", "PFPRB");
        wrappedPoolV1.initialize(address(proxyEquip), address(proxyRoleA));

        wrappedEquipV1.addActivePool(address(proxyPool));

        // vm mock user1 100 eth
        vm.deal(user1, 100 ether);
    }

    function testCanInitialize() public {
        // 测试初始化是否成功
        assertEq(wrappedEquipV1.symbol(), "PFPE");
        assertEq(wrappedRoleAV1.symbol(), "PFPRA");
        assertEq(wrappedRoleBV1.symbol(), "PFPRB");
    }

    // Test Role function
    function testGetSlotProps() public {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 0, 1023, 1, 0);
        assertEq(wrappedRoleAV1.getRoleId(tempSlot), 1);
        assertEq(wrappedRoleAV1.getRarity(tempSlot), 0);
        assertEq(wrappedRoleAV1.getVariant(tempSlot), 1023);
        assertEq(wrappedRoleAV1.getLevel(tempSlot), 1);
        assertEq(wrappedRoleAV1.getExp(tempSlot), 0);
    }

    function testAddExp_1() public {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 0, 1023, 1, 0); // level 1, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedRoleAV1.addExp(tempSlot, 21); // add 21 exp
        assertEq(wrappedRoleAV1.getLevel(newSlot), 3); // should be level3
        assertEq(wrappedRoleAV1.getExp(newSlot), 0); // and exp0
        assertEq(overflowExp, 0);
    }

    function testAddExp_2() public {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 0, 1023, 1, 0); // level 1, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedRoleAV1.addExp(tempSlot, 15); // add 15 exp
        assertEq(wrappedRoleAV1.getLevel(newSlot), 2); // should be level2
        assertEq(wrappedRoleAV1.getExp(newSlot), 5); // and exp 5
        assertEq(overflowExp, 0);
    }

    function testAddExp_3() public {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 0, 1023, 19, 0); // level 19, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedRoleAV1.addExp(tempSlot, 57); // add 57 exp
        assertEq(wrappedRoleAV1.getLevel(newSlot), 19); // should be level 19
        assertEq(wrappedRoleAV1.getExp(newSlot), 56); // and exp 56
        assertEq(overflowExp, 1); // and overflow
    }

    function testAddExp_4() public {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 0, 1023, 19, 0); // level 19, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedRoleAV1.addExp(tempSlot, 56); // add 56 exp
        assertEq(wrappedRoleAV1.getLevel(newSlot), 19); // should be level 19
        assertEq(wrappedRoleAV1.getExp(newSlot), 56); // and exp 56
        assertEq(overflowExp, 0);
    }

    function testAddExp_5() public {
        uint256 tempSlot = wrappedRoleAV1.generateSlot(1, 0, 1023, 19, 57); // level 19, exp 57
        (uint256 newSlot, uint32 overflowExp) = wrappedRoleAV1.addExp(tempSlot, 1); // add 1 exp
        assertEq(wrappedRoleAV1.getLevel(newSlot), 19); // should be level 19
        assertEq(wrappedRoleAV1.getExp(newSlot), 56); // and exp 56
        assertEq(overflowExp, 2); // will have more overflow exp, but not save in slot
    }

    function testActivePool() public {
        wrappedRoleAV1.addActivePool(address(wrappedPoolV1));
        assertTrue(wrappedRoleAV1.isActivePool(address(wrappedPoolV1)));
        wrappedRoleAV1.removeActivePool(address(wrappedPoolV1));
        assertFalse(wrappedRoleAV1.isActivePool(address(wrappedPoolV1)));
    }
}
