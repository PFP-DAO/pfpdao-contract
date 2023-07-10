// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {PFPDAOPool} from "../src/PFPDAOPool.sol";
import {PFPDAORole} from "../src/PFPDAORole.sol";
import {PFPDAOEquipment} from "../src/PFPDAOEquipment.sol";

contract InitPFPDAO is Script {
    PFPDAOPool wrappedPool;
    PFPDAORole wrappedRoleA;
    PFPDAOEquipment wrappedEquip;

    function run() public {
        address pool_ = vm.envAddress("POOL_ADDRESS");
        address role_ = vm.envAddress("ROLEA_ADDRESS");
        address equip_ = vm.envAddress("EQUIP_ADDRESS");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address admin_ = vm.rememberKey(privKey);

        vm.startBroadcast(admin_);
        wrappedPool = PFPDAOPool(pool_);
        wrappedRoleA = PFPDAORole(role_);
        wrappedEquip = PFPDAOEquipment(equip_);
        initNonce(wrappedPool);
        initRole(wrappedPool);
        initPrice(wrappedPool);
        initSigner(wrappedPool);
        initTreasury(wrappedPool);
        initRoleName(wrappedRoleA);
        initRole(wrappedRoleA, address(wrappedPool), address(wrappedEquip));
        initPool();
        initEquip(wrappedRoleA, wrappedEquip);
        vm.stopBroadcast();
    }

    function initPool() private {
        wrappedRoleA.addActivePool(address(wrappedPool));
        wrappedEquip.addActivePool(address(wrappedPool));
        require(wrappedRoleA.isActivePool(address(wrappedPool)));
        require(wrappedEquip.isActivePool(address(wrappedPool)));
    }

    function initNonce(PFPDAOPool pool_) private {
        pool_.setActiveNonce(1);
        require(pool_.activeNonce() == 1);
    }

    function initRole(PFPDAOPool pool_) private {
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
        pool_.setUpLegendaryId(upLegendaryId);
        pool_.setUpRareIds(upRareIds);
        pool_.setNormalLegendaryIds(normalLegendaryIds);
        pool_.setNormalRareIds(normalRareIds);
        pool_.setNormalCommonIds(normalCommonIds);

        require(pool_.upLegendaryId() == 1);
        require(pool_.getUpRareIdsLength() == 3);
        require(pool_.getNormalLegendaryIdsLength() == 0);
        require(pool_.getNormalRareIdsLength() == 0);
        require(pool_.getNormalCommonIdsLength() == 1);
    }

    function initPrice(PFPDAOPool pool_) private {
        pool_.setPriceLootOne(vm.envInt("PRICE_ONE"));
        pool_.setPriceLootTen(vm.envInt("PRICE_TEN"));
        require(pool_.priceLootOne() == vm.envInt("PRICE_ONE"));
        require(pool_.priceLootTen() == vm.envInt("PRICE_TEN"));
    }

    function initSigner(PFPDAOPool pool_) private {
        pool_.setSigner(vm.envAddress("SIGNER"));
        require(pool_.signer() == vm.envAddress("SIGNER"));
    }

    function initTreasury(PFPDAOPool pool_) private {
        pool_.setTreasury(vm.envAddress("TREASURY"));
        require(pool_.treasury() == vm.envAddress("TREASURY"));
    }

    function initRoleName(PFPDAORole role_) private {
        role_.setRoleName(1, "Linger");
        role_.setRoleName(2, "Kazuki");
        role_.setRoleName(3, "Mila");
        role_.setRoleName(4, "Mico");
    }

    function initRole(PFPDAORole role_, address pool_, address equip_) private {
        role_.addActivePool(pool_);
        require(role_.isActivePool(pool_));
        role_.setEquipmentContract(equip_);
        require(role_.equipmentContract() == address(equip_));
    }

    function initEquip(PFPDAORole role_, PFPDAOEquipment equip_) private {
        address[] memory allowedBurners = new address[](1);
        allowedBurners[0] = address(role_);
        equip_.updateAllowedBurners(allowedBurners);
    }
}
