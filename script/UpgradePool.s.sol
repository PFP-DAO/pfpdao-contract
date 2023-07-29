// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";
import {PFPDAOStyleVariantManager} from "../src/PFPDAOStyleVariantManager.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";

contract UpgradePool is Script {
    function run() public {
        // address pool = vm.envAddress("POOL_ADDRESS");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        // address roleNFTAddress_ = vm.envAddress("ROLEA_ADDRESS");
        // address equipmentAddress_ = vm.envAddress("EQUIP_ADDRESS");
        address styleAddress_ = vm.envAddress("STYLE_VARIANT_MANAGER");
        address deployer = vm.rememberKey(privKey);
        vm.startBroadcast(deployer);

        // 将代理合约包装成ABI，以支持更容易的调用
        // PFPDAOPool wrappedPoolV1 = PFPDAOPool(pool);
        // PFPDAOPool implementationV2 = new PFPDAOPool();
        // wrappedPoolV1.upgradeTo(address(implementationV2));

        // PFPDAORole wrappedRole = PFPDAORole(roleNFTAddress_);
        // PFPDAORole implementationRole = new PFPDAORole();
        // wrappedRole.upgradeTo(address(implementationRole));
        // wrappedRole.initialize(" PFPDAORoleA", "PFPRA", address(implementationV2));
        // wrappedRole.setRoleName(1, "Kazuki");
        // PFPDAOStyleVariantManager wrappedManager = PFPDAOStyleVariantManager(styleAddress_);
        // PFPDAOStyleVariantManager managerV2 = new PFPDAOStyleVariantManager();
        // wrappedManager.upgradeTo(address(managerV2));
        // assert(wrappedManager.viewLastVariant(1, 1) == 5);
        // assert(wrappedManager.viewLastVariant(1, 2) == 1);

        // wrappedRole.setStyleVariantManager(address(proxyManager));
        // wrappedPoolV1.setStyleVariantManager(address(proxyManager));

        // address account, uint16 roleId, uint8 style, uint32 value
        // address scoluo = 0x15DE3d7f7180f554421A91e27eE28a542881740D;
        // wrappedManager.setAddressToStyleVariant(scoluo, uint16(1), uint8(1), uint32(1));

        // kazuki

        // wrappedManager.setAddressToStyleVariant(
        //     0x6480A36FaC05ca38d38E03cA211B69091553a7A8, uint16(2), uint8(1), uint32(1)
        // );
        // wrappedManager.setAddressToStyleVariant(scoluo, uint16(2), uint8(1), uint32(2));
        // wrappedManager.setAddressToStyleVariant(
        //     0xDAC089de98659c57B4D5587548F75C76082c42eC, uint16(2), uint8(1), uint32(3)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x7A7D7A6d085b618f9060C064d61f47E99157Ab44, uint16(2), uint8(1), uint32(4)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x1960A7b4993A3E85CAd2f3E765111065cA3B3743, uint16(2), uint8(1), uint32(5)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0xce287AF8C6AEa6EBE1d29Ae97dBA93A264B38E65, uint16(2), uint8(1), uint32(6)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x074D20bEa26943A30aF0bED695A2925Eed9B0f37, uint16(2), uint8(1), uint32(7)
        // );

        // // mila
        // wrappedManager.setAddressToStyleVariant(scoluo, uint16(3), uint8(1), uint32(1));
        // wrappedManager.setAddressToStyleVariant(
        //     0x2eFc17E3De0BF18116A883e4fC068CF5F009729d, uint16(3), uint8(1), uint32(2)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x7B2e79d9b9C059227d8D7b4BB7a5E7dA361d2d4E, uint16(3), uint8(1), uint32(3)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0xDAC089de98659c57B4D5587548F75C76082c42eC, uint16(3), uint8(1), uint32(4)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x53779F2a0d43a2180974EF76D038e608d5F92F2A, uint16(3), uint8(1), uint32(5)
        // );

        // wrappedManager.setAddressToStyleVariant(
        //     0x7F97F1e1173741F971565779CBdEeDA97D60d164, uint16(3), uint8(1), uint32(6)
        // );

        // wrappedManager.setAddressToStyleVariant(
        //     0x9253d335c7359612357464023c1e1b2302b5659A, uint16(3), uint8(1), uint32(7)
        // );

        // wrappedManager.setAddressToStyleVariant(
        //     0x23395cD92c06Af055eB1C029F6F2d2B72c3705DD, uint16(3), uint8(1), uint32(8)
        // );

        // // mico

        // wrappedManager.setAddressToStyleVariant(
        //     0xb081240D03478236CD05A6c9Ca81C5a818863f89, uint16(4), uint8(1), uint32(1)
        // );
        // wrappedManager.setAddressToStyleVariant(scoluo, uint16(4), uint8(1), uint32(2));
        // wrappedManager.setAddressToStyleVariant(
        //     0xD431DFa080773288f73067BFB03f0c7817fbeE36, uint16(4), uint8(1), uint32(3)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x0225d0957963d3A31929D53fc6dbB186a4D45927, uint16(4), uint8(1), uint32(4)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0xd34da28c1e5708297e70b952cC280f52D9EF30Ab, uint16(4), uint8(1), uint32(5)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0xe8C16C288039F04de10997CD398cB10662182009, uint16(4), uint8(1), uint32(6)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x1960A7b4993A3E85CAd2f3E765111065cA3B3743, uint16(4), uint8(1), uint32(7)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x6eF0C2a8DddE33f211D686571453D1E1C5D4d2e1, uint16(4), uint8(1), uint32(8)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0xF91a41BdFd111763C43C721c93b0D9ec36846FB7, uint16(4), uint8(1), uint32(9)
        // );

        // assert(wrappedManager.viewRoleAwakenVariant(scoluo, uint16(1), uint8(1)) == uint32(1));
        // assert(wrappedManager.viewLastVariant(uint16(4), uint8(1)) == uint32(9));

        // linger

        // address[] memory to_ = new address[](5);
        // to_[0] = scoluo;
        // to_[1] = 0xeb3556E3eDC3bAC7c25138237F71f01857f6C5cc;
        // to_[2] = 0x49E53Fb3d5bf1532fEBAD88a1979E33A94844d1d;
        // to_[3] = 0x09793e61f7AF65f793a42655703BE7d3B079e6E1;
        // to_[4] = 0xD413c5f4C0F63232fD6e4edf24eA6fCCdA070308;
        // wrappedRole.airdrop(to_, 1, 2);

        // wrappedManager.setAddressToStyleVariant(
        //     0xeb3556E3eDC3bAC7c25138237F71f01857f6C5cc, uint16(1), uint8(1), uint32(2)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x49E53Fb3d5bf1532fEBAD88a1979E33A94844d1d, uint16(1), uint8(1), uint32(3)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0x09793e61f7AF65f793a42655703BE7d3B079e6E1, uint16(1), uint8(1), uint32(4)
        // );
        // wrappedManager.setAddressToStyleVariant(
        //     0xD413c5f4C0F63232fD6e4edf24eA6fCCdA070308, uint16(1), uint8(1), uint32(5)
        // );

        // assert(wrappedManager.viewRoleAwakenVariant(scoluo, uint16(1), uint8(1)) == uint32(1));
        // assert(wrappedManager.viewLastVariant(uint16(1), uint8(1)) == uint32(5));
        // 第一期有4个角色，0是装备，1是legendary, 2-4是rare
        // uint16 upSSSId = 1;
        // uint16[] memory upSSIds = new uint16[](3);
        // upSSIds[0] = 2;
        // upSSIds[1] = 3;
        // upSSIds[2] = 4;
        // uint16[] memory nSSSIds = new uint16[](0);
        // uint16[] memory nSSIds = new uint16[](0);
        // uint16[] memory nSIds = new uint16[](1);
        // nSIds[0] = 0;
        // wrappedPoolV1.setupSSSId(upSSSId);
        // wrappedPoolV1.setupSSIds(upSSIds);
        // wrappedPoolV1.setnSSSIds(nSSSIds);
        // wrappedPoolV1.setnSSIds(nSSIds);
        // wrappedPoolV1.setnSIds(nSIds);

        // wrappedPoolV1.setTreasury(vm.envAddress("TREASURY"));
        // wrappedPoolV1.setSigner(vm.envAddress("SIGNER"));

        // wrappedPoolV1.setPriceLootOne(vm.envInt("PRICE_ONE"));
        // wrappedPoolV1.setPriceLootTen(vm.envInt("PRICE_TEN"));

        // address roleA = address(wrappedPoolV1.roleNFT());
        // address equip = address(wrappedPoolV1.equipmentNFT());

        // assert(roleA == vm.envAddress("ROLEA_ADDRESS"));
        // assert(equip == vm.envAddress("EQUIP_ADDRESS"));

        // assert(wrappedPoolV1.priceLootOne() == vm.envInt("PRICE_ONE"));
        // assert(wrappedPoolV1.priceLootTen() == vm.envInt("PRICE_TEN"));

        // assert(wrappedPoolV1.treasury() == vm.envAddress("TREASURY"));
        // assert(wrappedPoolV1.signer() == vm.envAddress("SIGNER"));

        // assert(wrappedPoolV1.upSSSId() == 1);
        // assert(wrappedPoolV1.getupSSIdsLength() == 3);
        // assert(wrappedPoolV1.getnSSSIdsLength() == 0);
        // assert(wrappedPoolV1.getnSSIdsLength() == 0);
        // assert(wrappedPoolV1.getnSIdsLength() == 1);

        vm.stopBroadcast();
    }
}
