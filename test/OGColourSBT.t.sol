// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import {OGColourSBT, Minted, Soulbound} from "../src/OGColourSBT.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

contract OGColourSBTTest is PRBTest {
    OGColourSBT implementationSBTV1;

    UUPSProxy proxySBT;

    OGColourSBT wrappedSBTV1;

    address user1 = address(0x01);
    address user2 = address(0x02);

    function setUp() public {
        implementationSBTV1 = new OGColourSBT();

        // 部署代理合约并将其指向实现合约，这个是ERC1967Proxy
        proxySBT = new UUPSProxy(address(implementationSBTV1), "");

        // 将代理合约包装成ABI，以支持更容易的调用
        wrappedSBTV1 = OGColourSBT(address(proxySBT));

        // 初始化约合
        wrappedSBTV1.initialize();

        // vm mock user1 100 eth
        vm.deal(user1, 100 ether);
    }

    function testMint() public {
        vm.startPrank(user1);
        wrappedSBTV1.mint();
        uint256 colour1 = wrappedSBTV1.balanceOf(user1, 1);
        uint256 colour2 = wrappedSBTV1.balanceOf(user1, 2);
        uint256 colour3 = wrappedSBTV1.balanceOf(user1, 3);
        uint256 colour4 = wrappedSBTV1.balanceOf(user1, 4);
        uint256 colour5 = wrappedSBTV1.balanceOf(user1, 5);
        assertEq(colour1, 0);
        assertEq(colour2, 1);
        assertEq(colour3, 0);
        assertEq(colour4, 0);
        assertEq(colour5, 0);

        // max mint 1 per user
        vm.expectRevert(abi.encodeWithSelector(Minted.selector, user1));
        wrappedSBTV1.mint();

        // can get colour
        uint8 colour = wrappedSBTV1.userColour(user1);
        assertEq(colour, 2);

        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(user1);
        wrappedSBTV1.mint();
        vm.expectRevert(Soulbound.selector);
        wrappedSBTV1.safeTransferFrom(address(user1), address(user2), 0, 1, "");
        vm.stopPrank();
    }

    function testTokenUri() public {
        vm.startPrank(user1);
        wrappedSBTV1.mint();
        string memory uri = wrappedSBTV1.uri(2);
        assertEq(uri, "https://pfpdao-test-0.4everland.store/ogSBT/metadata/2");
        assertEq(wrappedSBTV1.uri(0), "");
        assertEq(wrappedSBTV1.uri(6), "");
        vm.stopPrank();
    }

    function testPause() public {
        assertFalse(wrappedSBTV1.paused());
        wrappedSBTV1.setPause(true);
        vm.expectRevert("Pausable: paused");
        vm.prank(user1);
        wrappedSBTV1.mint();
        assertTrue(wrappedSBTV1.paused());
        wrappedSBTV1.setPause(false);
        vm.prank(user1);
        wrappedSBTV1.mint();
    }
}
