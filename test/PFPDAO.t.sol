// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import {PFPDAO} from "../src/PFPDAO.sol";
// import {PFPDAOV2} from "../src/PFPDAOV2.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";

contract _PFPDAOTest is PRBTest {
    PFPDAO implementationV1;
    UUPSProxy proxy;
    PFPDAO wrappedProxyV1;
    // PFPDAOV2 wrappedProxyV2;

    address user1 = address(0x01);

    function setUp() public {
        implementationV1 = new PFPDAO(); // 初始化实现合约

        // 部署代理合约并将其指向实现合约，这个是ERC1967Proxy
        proxy = new UUPSProxy(address(implementationV1), "");

        // 将代理合约包装成ABI，以支持更容易的调用
        wrappedProxyV1 = PFPDAO(address(proxy));

        wrappedProxyV1.initialize(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // 初始化合约

        // wrappedProxyV1.initialize(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // mainnet

        // vm mock user1 100 eth
        vm.deal(user1, 100 ether);
    }

    function testCanInitialize() public {
        assertEq(wrappedProxyV1.symbol(), "PFP"); // 测试初始化是否成功
    }

    function testGetSlotProps() public {
        uint256 tempSlot = wrappedProxyV1.generateSlot(1, 0, 1023, 1, 0);
        console2.log("newSlot: %s", tempSlot);
        assertEq(wrappedProxyV1.getRoleId(tempSlot), 1);
        assertEq(wrappedProxyV1.getRarity(tempSlot), 0);
        assertEq(wrappedProxyV1.getVariant(tempSlot), 1023);
        assertEq(wrappedProxyV1.getLevel(tempSlot), 1);
        assertEq(wrappedProxyV1.getExp(tempSlot), 0);
    }

    function testAddExp1() public {
        uint256 tempSlot = wrappedProxyV1.generateSlot(1, 0, 1023, 1, 0); // level 1, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedProxyV1.addExp(tempSlot, 21); // add 21 exp
        assertEq(wrappedProxyV1.getLevel(newSlot), 3); // should be level3
        assertEq(wrappedProxyV1.getExp(newSlot), 0); // and exp0
        assertEq(overflowExp, 0);
    }

    function testAddExp2() public {
        uint256 tempSlot = wrappedProxyV1.generateSlot(1, 0, 1023, 1, 0); // level 1, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedProxyV1.addExp(tempSlot, 15); // add 15 exp
        assertEq(wrappedProxyV1.getLevel(newSlot), 2); // should be level2
        assertEq(wrappedProxyV1.getExp(newSlot), 5); // and exp 5
        assertEq(overflowExp, 0);
    }

    function testAddExp3() public {
        uint256 tempSlot = wrappedProxyV1.generateSlot(1, 0, 1023, 19, 0); // level 19, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedProxyV1.addExp(tempSlot, 57); // add 57 exp
        assertEq(wrappedProxyV1.getLevel(newSlot), 19); // should be level 19
        assertEq(wrappedProxyV1.getExp(newSlot), 56); // and exp 56
        assertEq(overflowExp, 1); // and overflow
    }

    function testAddExp4() public {
        uint256 tempSlot = wrappedProxyV1.generateSlot(1, 0, 1023, 19, 0); // level 19, exp 0
        (uint256 newSlot, uint32 overflowExp) = wrappedProxyV1.addExp(tempSlot, 56); // add 56 exp
        assertEq(wrappedProxyV1.getLevel(newSlot), 19); // should be level 19
        assertEq(wrappedProxyV1.getExp(newSlot), 56); // and exp 56
        assertEq(overflowExp, 0);
    }

    function testAddExp5() public {
        uint256 tempSlot = wrappedProxyV1.generateSlot(1, 0, 1023, 19, 57); // level 19, exp 57
        (uint256 newSlot, uint32 overflowExp) = wrappedProxyV1.addExp(tempSlot, 1); // add 1 exp
        assertEq(wrappedProxyV1.getLevel(newSlot), 19); // should be level 19
        assertEq(wrappedProxyV1.getExp(newSlot), 56); // and exp 56
        assertEq(overflowExp, 2); // will have more overflow exp, but not save in slot
    }

    function testMint() public {
        uint256 tempSlot = wrappedProxyV1.generateSlot(1, 0, 1, 1, 0);
        vm.prank(user1);
        wrappedProxyV1.mint{value: 3 ether}(tempSlot); // should pay 2.911 matic
        vm.prank(user1);
        vm.expectRevert();
        wrappedProxyV1.mint{value: 2.9 ether}(tempSlot);
    }

    // function testCanUpgrade() public {
    //     PFPDAOV2 implementationV2 = new PFPDAOV2(); // 部署新的实现合约
    //     wrappedProxyV1.upgradeTo(address(implementationV2)); // 升级实现合约，upgradeTo来自UUPSUpgradeable.sol

    //     // 重新包装代理合约
    //     wrappedProxyV2 = PFPDAOV2(address(proxy));

    //     uint256 tempSlot = 123012435;

    //     vm.prank(user1);
    //     wrappedProxyV2.mint(tempSlot);

    //     assertEq(wrappedProxyV2.balanceOf(user1), 1); // 获取user1的NFT balance
    //     assertEq(wrappedProxyV2.balanceOf(1), 2); // 获取tokenId是1的NFT的balance
    // }
}
