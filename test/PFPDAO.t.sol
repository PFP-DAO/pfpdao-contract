// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console.sol";

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

        wrappedProxyV1.initialize(); // 初始化合约
    }

    function testCanInitialize() public {
        assertEq(wrappedProxyV1.symbol(), "PFP"); // 测试初始化是否成功
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