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

    function initAll(address pool_, address role_, address equip_, address admin_) public {
        vm.startPrank(admin_);
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
    }

    function initNonce(PFPDAOPool pool_) public {
        pool_.setActiveNonce(1);
        assert(pool_.activeNonce() == 1);
    }

    function initRole(PFPDAOPool pool_) public {
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

        assert(pool_.upLegendaryId() == 1);
        assert(pool_.getUpRareIdsLength() == 3);
        assert(pool_.getNormalLegendaryIdsLength() == 0);
        assert(pool_.getNormalRareIdsLength() == 0);
        assert(pool_.getNormalCommonIdsLength() == 1);
    }

    function initPrice(PFPDAOPool pool_) public {
        pool_.setPriceLootOne(vm.envInt("PRICE_ONE"));
        pool_.setPriceLootTen(vm.envInt("PRICE_TEN"));
        assert(pool_.priceLootOne() == vm.envInt("PRICE_ONE"));
        assert(pool_.priceLootTen() == vm.envInt("PRICE_TEN"));
    }

    function initSigner(PFPDAOPool pool_) public {
        pool_.setSigner(vm.envAddress("SIGNER"));
        assert(pool_.signer() == vm.envAddress("SIGNER"));
    }

    function initTreasury(PFPDAOPool pool_) public {
        pool_.setTreasury(vm.envAddress("TREASURY"));
        assert(pool_.treasury() == vm.envAddress("TREASURY"));
    }

    function initRoleName(PFPDAORole role_) public {
        role_.setRoleName(1, "Linger");
        role_.setRoleName(2, "Kazuki");
        role_.setRoleName(3, "Mila");
        role_.setRoleName(4, "Mico");
    }

    function initRole(PFPDAORole role_, address pool_, address equip_) public {
        role_.addActivePool(pool_);
        assert(role_.isActivePool(pool_));
        role_.setEquipmentContract(equip_);
        assert(role_.equipmentContract() == address(equip_));
    }
}
