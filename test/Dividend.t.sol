// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PRBTest} from "@prb/test/PRBTest.sol";
import "forge-std/console2.sol";

import {PFPDAOEquipment, NotBurner} from "../src/PFPDAOEquipment.sol";
import {PFPDAOPool, NotEnoughMATIC} from "../src/PFPDAOPool.sol";
import {PFPDAOEquipMetadataDescriptor} from "../src/PFPDAOEquipMetadataDescriptor.sol";
import {PFPDAORole, Soulbound, InvalidSlot, NotAllowed, NotOwner} from "../src/PFPDAORole.sol";
import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";
import {Dividend} from "../src/Dividend.sol";
import {IERC20} from "@uniswap/periphery/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function approve(address guy, uint256 wad) external returns (bool);
}

contract _DividendTest is PRBTest {
    PFPDAOPool implementationPoolV1;
    PFPDAOEquipment implementationEquipV1;
    PFPDAORole implementationRoleAV1;
    PFPDAORole implementationRoleBV1;
    PFPDAOEquipMetadataDescriptor implementationMetadataDescriptor;
    PFPDAOStyleVariantManager implementationStyleManagerV1;
    Dividend implementationDividend;

    UUPSProxy proxyPool;
    UUPSProxy proxyEquip;
    UUPSProxy proxyRoleA;
    UUPSProxy proxyRoleB;
    UUPSProxy proxyMetadataDescriptor;
    UUPSProxy proxyStyleManager;
    UUPSProxy proxyDividend;

    PFPDAOPool wrappedPoolV1;
    PFPDAOEquipment wrappedEquipV1;
    PFPDAORole wrappedRoleAV1;
    PFPDAORole wrappedRoleBV1;
    PFPDAOEquipMetadataDescriptor wrappedMetadataDescriptor;
    PFPDAOStyleVariantManager wrappedStyleManagerV1;
    Dividend wrappedDividend;

    address signer;
    uint256 signerPrivateKey = 0xabcdf1234567890abcdef1234567890abcdef1234567890abcdef1234567890;
    address admin = address(0x01);
    address user1 = address(0x02);
    address treasury = address(0x03);
    address user2 = address(0x04);
    address relayer = address(0x05);
    IWETH wmatic = IWETH(vm.envAddress("WMATIC"));
    IERC20 usdc = IERC20(vm.envAddress("USDC"));
    IUniswapV2Router02 swapRouter = IUniswapV2Router02(vm.envAddress("SWAP_ROUTER")); // quickswap testnet

    AggregatorV3Interface internal dataFeed;
    address oracle;

    function setUp() public {
        string memory rpc = vm.envString("RPC_URL");
        uint256 forkId = vm.createFork(rpc);
        vm.selectFork(forkId);

        oracle = vm.envAddress("MATICUSD");

        signer = vm.addr(signerPrivateKey);

        implementationPoolV1 = new PFPDAOPool();
        implementationEquipV1 = new PFPDAOEquipment();
        implementationRoleAV1 = new PFPDAORole();
        implementationRoleBV1 = new PFPDAORole();
        implementationMetadataDescriptor = new PFPDAOEquipMetadataDescriptor();
        implementationStyleManagerV1 = new PFPDAOStyleVariantManager();
        implementationDividend = new Dividend();

        // 部署代理合约并将其指向实现合约，这个是ERC1967Proxy
        proxyPool = new UUPSProxy(address(implementationPoolV1), "");
        proxyEquip = new UUPSProxy(address(implementationEquipV1), "");
        proxyRoleA = new UUPSProxy(address(implementationRoleAV1), "");
        proxyRoleB = new UUPSProxy(address(implementationRoleBV1), "");
        proxyMetadataDescriptor = new UUPSProxy(address(implementationMetadataDescriptor), "");
        proxyStyleManager = new UUPSProxy(address(implementationStyleManagerV1), "");
        proxyDividend = new UUPSProxy(address(implementationDividend), "");

        // 将代理合约包装成ABI，以支持更容易的调用
        wrappedPoolV1 = PFPDAOPool(address(proxyPool));
        wrappedEquipV1 = PFPDAOEquipment(address(proxyEquip));
        wrappedRoleAV1 = PFPDAORole(address(proxyRoleA));
        wrappedRoleBV1 = PFPDAORole(address(proxyRoleB));
        wrappedMetadataDescriptor = PFPDAOEquipMetadataDescriptor(address(proxyMetadataDescriptor));
        wrappedStyleManagerV1 = PFPDAOStyleVariantManager(address(proxyStyleManager));
        wrappedDividend = Dividend(address(proxyDividend));

        // 初始化合约
        wrappedPoolV1.initialize(address(proxyEquip), address(proxyRoleA));
        wrappedPoolV1.setStyleVariantManager(address(proxyStyleManager));
        wrappedEquipV1.initialize();
        wrappedRoleAV1.initialize("PFPDAORoleA", "PFPRA");
        wrappedRoleBV1.initialize("PFPDAORoleB", "PFPRB");
        wrappedStyleManagerV1.initialize(address(wrappedPoolV1), address(wrappedRoleAV1));
        wrappedRoleAV1.setStyleVariantManager(address(proxyStyleManager));
        wrappedRoleBV1.setStyleVariantManager(address(proxyStyleManager));
        wrappedDividend.initialize(address(usdc), address(wrappedPoolV1), address(wrappedRoleAV1));

        dataFeed = AggregatorV3Interface(oracle);

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
        wrappedPoolV1.setWETH(address(wmatic));
        wrappedPoolV1.setUSDC(address(usdc));
        wrappedPoolV1.setFeed(oracle);
        wrappedPoolV1.setRelayer(address(relayer));
        wrappedPoolV1.setSwapRouter(address(swapRouter));
        wrappedPoolV1.setUseNewPrice(true);

        wrappedRoleAV1.setEquipmentContract(address(proxyEquip));
        wrappedEquipV1.setMetadataDescriptor(address(proxyMetadataDescriptor));
        wrappedRoleAV1.setDividend(address(proxyDividend));

        address[] memory allowedBurners = new address[](1);
        allowedBurners[0] = address(wrappedRoleAV1);
        wrappedEquipV1.updateAllowedBurners(allowedBurners);

        // vm mock user1 100 eth
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);

        address[] memory to1 = new address[](1);
        to1[0] = user1;
        wrappedRoleAV1.airdrop(to1, 3, 1);
        wrappedRoleAV1.airdrop(to1, 3, 1);
        wrappedRoleAV1.airdrop(to1, 3, 1);
        wrappedRoleAV1.airdrop(to1, 3, 1);

        address[] memory to2 = new address[](1);
        to2[0] = user2;
        wrappedRoleAV1.airdrop(to2, 3, 1);
        wrappedRoleAV1.airdrop(to2, 3, 1);

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
        assertEq(address(wrappedDividend.usdcAddress()), address(usdc));
        assertEq(address(wrappedRoleAV1.dividend()), address(proxyDividend));

        assertEq(wrappedDividend.captainRightDenominator(3), 60);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 40); // user1 has 2 level 20 mila
        assertEq(wrappedDividend.addressCaptainRight(user2, 3), 20); // user2 has 1 level 20 mila
        assertEq(wrappedDividend.roleIdPoolBalance(3), 0);
    }

    function testSwapToken() public {
        address[] memory path = new address[](2);
        path[0] = address(wmatic);
        path[1] = address(usdc);
        uint256 amountOutMin = 0;
        address to = address(this);
        uint256 deadline = block.timestamp + 100;
        uint256 beforeUSDCBalance = usdc.balanceOf(address(this));
        uint256 beforeMaticBalance = address(this).balance;
        swapRouter.swapExactETHForTokens{value: 1 ether}(amountOutMin, path, to, deadline);
        uint256 afterUSDCBalance = usdc.balanceOf(address(this));
        assertEq(beforeMaticBalance, address(this).balance + 1 ether);
        assertGt(afterUSDCBalance, beforeUSDCBalance);
    }

    function testLevelChangeRight() public {
        vm.startPrank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        uint256[] memory equipsToBurn = new uint256[](2);
        equipsToBurn[0] = 1; // level to 21
        equipsToBurn[1] = 2; // level to 22
        wrappedRoleAV1.levelUpByBurnEquipments(1, equipsToBurn);
        vm.stopPrank();

        assertEq(wrappedDividend.captainRightDenominator(3), 22 + 20 + 20);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 22 + 20);

        vm.startPrank(user2);
        wrappedPoolV1.loot10{value: 22 ether}(false);
        wrappedPoolV1.loot10{value: 22 ether}(false);
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

    event Claim(address indexed user, uint16 indexed roleId, uint256 amount, uint256 batch);

    function testDailyDivide() public {
        uint256 oldTreasury = usdc.balanceOf(treasury);
        uint256 user1USDCBalance = usdc.balanceOf(user1);

        assertEq(wrappedDividend.lastClaimedTimestamp(user1, 3), 0); // user1上一次claim时间是0
        vm.prank(user1);
        wrappedPoolV1.loot10{value: 22 ether}(3, 1, false); // nftid 1 as captain, roleId is 3, loot with matic
        assertEq(address(wrappedPoolV1).balance, 22 ether);

        uint256 dailyBeforeUSDCBalance = usdc.balanceOf(address(wrappedDividend));
        assertEq(dailyBeforeUSDCBalance, 0);

        vm.startPrank(relayer);
        uint16[] memory roleIds1 = new uint16[](1);
        roleIds1[0] = 3;
        uint256 role3TotalBalance = wrappedDividend.roleIdPoolBalance(3); // old role 3 balance
        assertEq(role3TotalBalance, 0);

        (, int256 answer,,,) = dataFeed.latestRoundData();

        uint256[] memory roleIdPoolBalanceTodayFail = new uint256[](1);
        roleIdPoolBalanceTodayFail[0] = uint256((0 + 11) * answer * 10 ** 6 / (10 ** 8)); // 原余额+今日收入。1e6是usdc的精度，1e8是预言机汇率的精度

        vm.expectRevert("Need all roleIds");
        wrappedPoolV1.dailyDivide(roleIds1, roleIdPoolBalanceTodayFail);

        uint256[] memory roleIdPoolBalanceToday = new uint256[](4);
        roleIdPoolBalanceToday[0] = 0;
        roleIdPoolBalanceToday[1] = 0;
        roleIdPoolBalanceToday[2] = uint256((0 + 11) * answer * 10 ** 6 / (10 ** 8));
        roleIdPoolBalanceToday[3] = 0;

        uint16[] memory roleIds4 = new uint16[](4);
        roleIds4[0] = 1;
        roleIds4[1] = 2;
        roleIds4[2] = 3;
        roleIds4[3] = 4;
        wrappedPoolV1.dailyDivide(roleIds4, roleIdPoolBalanceToday);

        uint256 afterDividedUSDCBalance = usdc.balanceOf(address(wrappedDividend));
        assertGt(afterDividedUSDCBalance, 5 * 10 ** 6); // 11 matic 应该 大于5u
        assertEq(afterDividedUSDCBalance, usdc.balanceOf(treasury) - oldTreasury);
        vm.stopPrank();

        assertGt(wrappedDividend.roleIdPoolBalance(3), 5 * 10 ** 6); // 角色3的奖池应该大于5u
        assertGt(wrappedDividend.batchRoleIdPoolBalance(2, 3), 1 * 10 ** 5); // 角色3的奖池应该大于0.1u
        assertLt(wrappedDividend.batchRoleIdPoolBalance(2, 3), 2 * 10 ** 5); // 角色3的奖池应该小于0.2u

        assertEq(wrappedDividend.batchAddressCaptainRight(1, user1, 3), 40); // batch1, user1的角色3的权益应该为40
        assertEq(wrappedDividend.batchAddressCaptainRight(2, user1, 3), 0); // batch2, user1的角色3的权益应该为0
        assertEq(wrappedDividend.batchCaptainRight(1, 3), 40); //  batch1, 角色3的总权益应该为40
        assertEq(wrappedDividend.batchCaptainRight(2, 3), 0); //  batch2, 角色3的总权益应该为0

        vm.prank(user1);
        wrappedPoolV1.loot1{value: 2.8 ether}(3, 1, false); // user1在batch2再次用matic去loot
        assertGt(usdc.balanceOf(user1) - user1USDCBalance, 1 * 10 ** 5); // user1 应该获得了分红，大于0.1u
        assertEq(wrappedDividend.batchAddressCaptainRight(2, user1, 3), 40);
        assertEq(wrappedDividend.batchCaptainRight(2, 3), 40);
        assertEq(wrappedDividend.lastClaimedTimestamp(user1, 3), block.timestamp); // user1上一次claim时间是当前区块
    }

    function testContribute() public {
        vm.startPrank(user2);
        address[] memory path = new address[](2);
        path[0] = address(wrappedPoolV1.weth());
        path[1] = address(wrappedPoolV1.usdc());
        IUniswapV2Router02(wrappedPoolV1.router()).swapExactETHForTokens{value: 10 ether}(
            0, path, address(user2), block.timestamp + 5 minutes
        );
        uint256 usdcBalanceBefore = usdc.balanceOf(address(user2));
        assertGt(usdcBalanceBefore, 1);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        uint256 amount = 5 * 10 ** 6; // 5 u
        wrappedDividend.contribute(3, amount);

        usdc.approve(address(wrappedDividend), amount);
        wrappedDividend.contribute(3, amount);

        assertEq(wrappedDividend.roleIdPoolBalance(3), amount);
        uint256 usdcBalanceAfter = usdc.balanceOf(address(user2));
        assertEq(usdcBalanceAfter, usdcBalanceBefore - amount);
        vm.stopPrank();
    }

    function testViewByWebsite() public {
        // 1. 可以查看持有的某个角色占全网的权重
        assertEq(wrappedDividend.getRightByRole(user2, 3), 3333); // 1/3
        assertEq(wrappedDividend.getRightByRole(user2, 1), 0);

        // 2. 可以查预计当次loot能获得多少USDC
        assertEq(wrappedDividend.getClaimAmount(user2, 3), 0);
        vm.prank(user2);
        wrappedPoolV1.loot10{value: 22 ether}(3, 1, false);

        uint256[] memory roleIdPoolBalanceToday = new uint256[](4);
        roleIdPoolBalanceToday[0] = 0;
        roleIdPoolBalanceToday[1] = 0;
        (, int256 answer,,,) = dataFeed.latestRoundData();
        roleIdPoolBalanceToday[2] = uint256((0 + 11) * answer * 10 ** 6 / (10 ** 8));
        roleIdPoolBalanceToday[3] = 0;
        uint16[] memory roleIds4 = new uint16[](4);
        roleIds4[0] = 1;
        roleIds4[1] = 2;
        roleIds4[2] = 3;
        roleIds4[3] = 4;

        vm.prank(relayer);
        wrappedPoolV1.dailyDivide(roleIds4, roleIdPoolBalanceToday);

        // 可以查看当次looot预计有多少usdc
        assertGt(wrappedDividend.getClaimAmount(user2, 3), 1 * 10 ** 5);
        assertEq(wrappedDividend.getClaimAmount(user2, 1), 0);
        vm.startPrank(user2);
        uint256 usdcBalance1 = usdc.balanceOf(address(user2));
        wrappedPoolV1.loot1{value: 2.8 ether}(3, 1, false);
        uint256 usdcBalance2 = usdc.balanceOf(address(user2));
        assertGt(usdcBalance2, usdcBalance1);
        // 当天的重复loot不会再次获得USDC
        wrappedPoolV1.loot1{value: 2.8 ether}(3, 1, false);
        uint256 usdcBalance3 = usdc.balanceOf(address(user2));
        assertEq(usdcBalance2, usdcBalance3);

        // 3. 可以查上一次领分红的时间
        assertEq(wrappedDividend.getLastLootTimestamp(user2, 3), block.timestamp);
    }

    function testNewPayPrice() public {
        vm.prank(user2);
        wrappedPoolV1.loot10{value: 22 ether}(3, 1, false);
        uint256 userMaticBalance = address(user2).balance;

        wrappedPoolV1.setUseNewPrice(false);
        vm.expectRevert(NotEnoughMATIC.selector);
        vm.startPrank(user2);
        wrappedPoolV1.loot10{value: 22 ether}(3, 1, false); // new method need 30+ matic (22/maticusd)

        (, int256 answer,,,) = dataFeed.latestRoundData();
        uint256 shouldPay = uint256((22 ether * 10 ** 8) / answer);
        wrappedPoolV1.loot10{value: shouldPay}(3, 1, false);
        assertAlmostEq(address(user2).balance + shouldPay, userMaticBalance, 0.1 ether);
        vm.stopPrank();
    }

    function _swapSomeUSDC() private {
        address[] memory path = new address[](2);
        path[0] = address(wmatic);
        path[1] = address(usdc);
        uint256 amountOutMin = 0;
        address to = address(this);
        uint256 deadline = block.timestamp + 100;
        swapRouter.swapExactETHForTokens{value: 500 ether}(amountOutMin, path, to, deadline);
    }

    function testNewPayMethod() public {
        _swapSomeUSDC();
        usdc.transfer(user1, 100 * 10 ** 6);
        uint256 user1OldUSDCBalance1 = usdc.balanceOf(user1); // 100 usdc
        uint256 poolUSDCBalance1 = usdc.balanceOf(address(wrappedPoolV1)); // 0 usdc
        assertAlmostEq(user1OldUSDCBalance1, 100 * 10 ** 6, 10 ** 5); //user1 have 100 usdc initially
        vm.startPrank(user1);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        wrappedPoolV1.loot10(3, 1, true);
        usdc.approve(address(wrappedPoolV1), 100 * 10 ** 6);
        console2.log(usdc.allowance(user1, address(wrappedPoolV1)));
        wrappedPoolV1.loot10(3, 1, true);

        assertEq(usdc.balanceOf(address(wrappedPoolV1)), poolUSDCBalance1 + 22 * 10 ** 6);

        uint256[] memory roleIdPoolBalanceToday = new uint256[](4);
        roleIdPoolBalanceToday[0] = 0;
        roleIdPoolBalanceToday[1] = 0;
        roleIdPoolBalanceToday[2] = 11 * 10 ** 6;
        roleIdPoolBalanceToday[3] = 0;

        uint16[] memory roleIds4 = new uint16[](4);
        roleIds4[0] = 1;
        roleIds4[1] = 2;
        roleIds4[2] = 3;
        roleIds4[3] = 4;

        vm.prank(relayer);
        wrappedPoolV1.dailyDivide(roleIds4, roleIdPoolBalanceToday);

        assertEq(wrappedDividend.roleIdPoolBalance(3), 98 * 11 * 10 ** 4); // 98% of 11u
        assertEq(wrappedDividend.batchRoleIdPoolBalance(2, 3), 22 * 10 ** 4); // 2% of 11u
        assertEq(wrappedDividend.batchAddressCaptainRight(1, user1, 3), 40);
        assertEq(wrappedDividend.batchAddressCaptainRight(1, user2, 3), 0);
        assertEq(wrappedDividend.batchAddressCaptainRight(2, user1, 3), 0);
        assertEq(wrappedDividend.batchCaptainRight(1, 3), 40);
        assertEq(wrappedDividend.batchCaptainRight(2, 3), 0);
    }

    function testTwoUserUseDifferentMethod() public {
        _swapSomeUSDC();
        (, int256 answer,,,) = dataFeed.latestRoundData();

        usdc.transfer(user1, 66 * 10 ** 6);
        usdc.transfer(user2, 66 * 10 ** 6);

        vm.startPrank(user1);
        usdc.approve(address(wrappedPoolV1), 22 * 10 ** 6);
        wrappedPoolV1.loot10(3, 1, true);
        vm.stopPrank();

        vm.prank(user2);
        uint256 shouldPay10 = uint256((22 ether * 10 ** 8) / answer);
        uint256 shouldPay1 = uint256((28 ether * 10 ** 7) / answer);
        wrappedPoolV1.loot10{value: shouldPay10}(3, 5, false);

        vm.prank(relayer);
        uint256[] memory roleIdPoolBalanceToday = new uint256[](4);
        roleIdPoolBalanceToday[0] = 0;
        roleIdPoolBalanceToday[1] = 0;
        roleIdPoolBalanceToday[2] = 21933326; // can get from tranfer event
        roleIdPoolBalanceToday[3] = 0;

        uint16[] memory roleIds4 = new uint16[](4);
        roleIds4[0] = 1;
        roleIds4[1] = 2;
        roleIds4[2] = 3;
        roleIds4[3] = 4;
        wrappedPoolV1.dailyDivide(roleIds4, roleIdPoolBalanceToday);

        assertAlmostEq(wrappedDividend.roleIdPoolBalance(3), 98 * 22 * 10 ** 4, 100000); // 98% of 22u, 0.1误差
        assertAlmostEq(wrappedDividend.batchRoleIdPoolBalance(2, 3), 2 * 22 * 10 ** 4, 10000); // 2% of 22u, 0.01误差
        assertEq(wrappedDividend.batchAddressCaptainRight(1, user1, 3), 40);
        assertEq(wrappedDividend.batchAddressCaptainRight(1, user2, 3), 20);
        assertEq(wrappedDividend.batchAddressCaptainRight(2, user1, 3), 0);
        assertEq(wrappedDividend.batchCaptainRight(1, 3), 60);
        assertEq(wrappedDividend.batchCaptainRight(2, 3), 0);

        vm.startPrank(user1);
        uint256 user1USDCBalance1 = usdc.balanceOf(user1);
        wrappedPoolV1.loot1{value: shouldPay1}(3, 1, false);
        uint256 user1USDCBalance2 = usdc.balanceOf(user1);
        wrappedPoolV1.loot1{value: shouldPay1}(3, 1, false);
        uint256 user1USDCBalance3 = usdc.balanceOf(user1);

        assertGt(user1USDCBalance2, user1USDCBalance1);
        assertEq(user1USDCBalance3, user1USDCBalance2);
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(wrappedPoolV1), 248 * 10 ** 5);
        uint256 user2USDCBalance1 = usdc.balanceOf(user2);
        wrappedPoolV1.loot1(3, 5, true);
        uint256 user2USDCBalance2 = usdc.balanceOf(user2);
        wrappedPoolV1.loot10(3, 5, true);
        uint256 user2USDCBalance3 = usdc.balanceOf(user2);

        assertGt(user2USDCBalance2 + 28 * 10 ** 5, user2USDCBalance1);
        assertEq(user2USDCBalance3 + 22 * 10 ** 6, user2USDCBalance2);
        vm.stopPrank();

        assertEq(wrappedDividend.batch(), 2);
        vm.prank(relayer);
        uint256[] memory roleIdPoolBalanceToday_2 = new uint256[](4);
        roleIdPoolBalanceToday_2[0] = 0;
        roleIdPoolBalanceToday_2[1] = 0;
        roleIdPoolBalanceToday_2[2] = (220 + 28 * 3) * 10 ** 5 / 2; // should be caculate 1/2
        roleIdPoolBalanceToday_2[3] = 0;

        uint16[] memory roleIds4_2 = new uint16[](4);
        roleIds4_2[0] = 1;
        roleIds4_2[1] = 2;
        roleIds4_2[2] = 3;
        roleIds4_2[3] = 4;
        wrappedPoolV1.dailyDivide(roleIds4_2, roleIdPoolBalanceToday_2);
        assertEq(wrappedDividend.batch(), 3);
        assertAlmostEq(
            wrappedDividend.roleIdPoolBalance(3), 98 * (98 * 22 * 10 ** 4 + (220 + 28 * 3) * 10 ** 5 / 2) / 100, 500000
        ); // (98% of 22u + 2.8*4/2)的98%, 0.5误差
        assertAlmostEq(
            wrappedDividend.batchRoleIdPoolBalance(3, 3),
            2 * (98 * 22 * 10 ** 4 + (220 + 28 * 3) * 10 ** 5 / 2) / 100,
            10000
        ); // (98% of 22u + 2.8*4/2)的2% of 22u, 0.01误差
        assertEq(wrappedDividend.batchAddressCaptainRight(2, user1, 3), 40);
        assertEq(wrappedDividend.batchAddressCaptainRight(2, user2, 3), 20);
        assertEq(wrappedDividend.batchCaptainRight(2, 3), 60);
    }

    function testLevelUpChangeWeight() public {
        wrappedRoleAV1.setRoleLevelAndExp(1, 20, 60);
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 40);
        assertEq(wrappedRoleAV1.getLevel(1), 20);
        vm.prank(user1);
        wrappedPoolV1.loot1{value: 2.8 ether}(3, 1, false); // level up 20 to 21
        assertEq(wrappedDividend.addressCaptainRight(user1, 3), 41);
        assertEq(wrappedDividend.addressCaptainRight(address(wrappedPoolV1), 3), 0);
        assertEq(wrappedRoleAV1.getLevel(1), 21);
    }
}
