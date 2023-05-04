// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {PFPDAO} from "./PFPDAO.sol";
import {PFPDAORoleVariantManager} from "./PFPDAORoleVariantManager.sol";
import {PFPDAOEquipment} from "./PFPDAOEquipment.sol";
import {PFPDAORole} from "./PFPDAORole.sol";

import "@chainlink/interfaces/AggregatorV3Interface.sol";

import "forge-std/console2.sol";

error PoolNotSet();

contract PFPDAOPool is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PFPDAORoleVariantManager
{
    int256 public priceLootOne;
    int256 public priceLootTen;

    mapping(address => uint8) public mintTimesForSSS;
    mapping(address => bool) public nextIsUpSSS;
    mapping(address => uint8) public mintTimesForUpSS;

    AggregatorV3Interface internal priceFeed;

    // 部署池子的时候，应该指定装备地址和角色NFT地址
    PFPDAOEquipment public equipmentNFT;
    PFPDAORole public roleNFT;
    // PFPDAO public pfpdao;

    uint16 public upLegendaryId;
    uint16[] public upRareIds;
    uint16[] public normalLegendaryIds;
    uint16[] public normalRareIds;
    uint16[] public normalCommonIds;

    // 50%的资金进入角色关联的池子
    mapping(uint16 => uint256) public roleIdPoolBalance;
    uint16 defaultRoleIdForNewUser;

    function __PFPDAOPool_init() internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function __PFPDAO_init_unchained() internal onlyInitializing {
        // https://docs.chain.link/data-feeds/price-feeds/addresses/?network=polygon
        // mainnet 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);

        priceLootOne = 2.8e8; // 2.8 U
        priceLootTen = 22e8; // 22 U

        equipmentNFT.addActivePool(address(this));
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address equipmentAddress_, address roleNFTAddress_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __PFPDAOPool_init();
        equipmentNFT = PFPDAOEquipment(equipmentAddress_);
        roleNFT = PFPDAORole(roleNFTAddress_);
        defaultRoleIdForNewUser = 1;
    }

    modifier loot1PayVerify() {
        int256 lastPrice = getLatestPrice();
        uint256 shouldPay = uint256(priceLootOne * 1e18 / lastPrice);
        require(msg.value > shouldPay, "Not enough MATIC");
        _;
    }

    modifier loot10PayVerify() {
        int256 lastPrice = getLatestPrice();
        uint256 shouldPay = uint256(priceLootTen * 1e18 / lastPrice);
        require(msg.value > shouldPay, "Not enough MATIC");
        _;
    }

    function getLatestPrice() public view returns (int256) {
        // (, int256 price,,,) = priceFeed.latestRoundData();
        // return price;
        return 96180000; // price 96180000 == 0.9618 U for mock
    }

    function _loot1() private {
        uint256 tmpSlot = _mintLogic(1);

        if (equipmentNFT.getRarity(tmpSlot) == 0) {
            equipmentNFT.mint(_msgSender(), tmpSlot, 1);
        } else {
            roleNFT.mint(_msgSender(), tmpSlot, 1);
        }
    }

    function loot1() external payable loot1PayVerify {
        roleIdPoolBalance[defaultRoleIdForNewUser] += msg.value / 2;
        _loot1();
    }

    function loot1(uint16 captainId_, uint256 nftId_) external payable loot1PayVerify {
        roleIdPoolBalance[captainId_] += msg.value / 2;
        _loot1();
        roleNFT.levelUp(nftId_, 2);
    }

    function _loot10() private {
        uint256[] memory slots = new uint256[](10);
        uint8[] memory balance = new uint8[](10);

        for (uint8 i = 0; i < 10; i++) {
            uint256 tmpSlot = _mintLogic(i);
            for (uint8 j = 0; j < slots.length; j++) {
                if (slots[j] == tmpSlot) {
                    balance[j]++;
                } else {
                    slots[i] = tmpSlot;
                    balance[i] = 1;
                }
                break;
            }
        }

        for (uint8 i = 0; i < balance.length; i++) {
            if (balance[i] == 0) continue;
            if (roleNFT.getRarity(slots[i]) == 0) {
                console2.log("slot: %s, balance: %s", slots[i], balance[i]);
                uint256 tokenId = equipmentNFT.mint(_msgSender(), slots[i], balance[i]);
            } else {
                roleNFT.mint(_msgSender(), slots[i], balance[i]);
                console2.log("slot: %s, balance: %s", slots[i], balance[i]);
            }
        }
    }

    function loot10() external payable loot10PayVerify {
        roleIdPoolBalance[defaultRoleIdForNewUser] += msg.value / 2;
        _loot10();
    }

    function loot10(uint16 captainId_, uint256 nftId_) external payable loot10PayVerify {
        roleIdPoolBalance[captainId_] += msg.value / 2;
        _loot10();
        roleNFT.levelUp(nftId_, 20);
    }

    function _mintLogic(uint8 _time) private returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, block.difficulty, _time)));
        uint16 roleId;
        uint8 rarity;

        // 进行随机数判断。先判断角色大保底，然后是角色保底，最后是10次保底
        // 1. 角色大保底：每次抽到 **Legendary** 的角色如果不是本期up角色，下一次抽到 **Legendary** 的角色必定是本期up角色。
        // 2. 角色保底：每90次抽卡必定获得一个 **Legendary** 传说级角色
        // 3. 抽满10次保底，必定有个rare角色，4分之3出本期up角，4分之1出常驻池

        if (nextIsUpSSS[_msgSender()]) {
            // 角色大保底
            roleId = upLegendaryId;
            rarity = 2;
            nextIsUpSSS[_msgSender()] = false;
            mintTimesForSSS[_msgSender()] = 0;
        } else if (mintTimesForSSS[_msgSender()] == 90) {
            // 角色保底：每90次抽卡必定获得一个Legendary传说级角色
            if (normalLegendaryIds.length == 0) {
                roleId = upLegendaryId;
            } else if (seed % (normalLegendaryIds.length + 1) == 0) {
                roleId = upLegendaryId;
            } else {
                roleId = normalLegendaryIds[seed % normalLegendaryIds.length];
            }
            rarity = 2;
            mintTimesForSSS[_msgSender()] = 0;
        } else if (mintTimesForUpSS[_msgSender()] == 10) {
            if (normalRareIds.length == 0) {
                roleId = upRareIds[seed % upRareIds.length];
            } else if (seed % 4 == 0) {
                roleId = upRareIds[seed % upRareIds.length];
            } else {
                roleId = normalRareIds[seed % normalRareIds.length];
            }
            rarity = 1;
        } else {
            // 1% Legendary, 10% Rare, 89% Common
            uint8 randomValue = uint8(seed % 100);
            console2.log("randomValue", randomValue);
            if (randomValue < 1) {
                if (normalLegendaryIds.length == 0) {
                    roleId = upLegendaryId;
                } else if (seed % (normalLegendaryIds.length + 1) == 0) {
                    roleId = upLegendaryId;
                } else {
                    roleId = normalLegendaryIds[seed % normalLegendaryIds.length];
                }
                rarity = 2;
                mintTimesForSSS[_msgSender()] = 0;
                mintTimesForUpSS[_msgSender()] += 1;
            } else if (randomValue < 11) {
                if (seed % (upRareIds.length + normalRareIds.length) <= upRareIds.length) {
                    roleId = upRareIds[seed % upRareIds.length];
                } else {
                    roleId = normalRareIds[seed % normalRareIds.length];
                }
                rarity = 1;
                mintTimesForSSS[_msgSender()] += 1;
                mintTimesForUpSS[_msgSender()] = 0;
            } else {
                rarity = 0;
                roleId = normalCommonIds[seed % normalCommonIds.length];
                mintTimesForSSS[_msgSender()] += 1;
                mintTimesForUpSS[_msgSender()] += 1;
            }
        }

        uint32 variant;
        if (rarity == 0) {
            variant = 0;
        } else {
            variant = getRoleVariant(_msgSender(), roleId);
        }
        uint256 newSlot = roleNFT.generateSlot(roleId, rarity, variant, 1, 0);
        return newSlot;
    }

    /* admin functions */
    function setPoolRoleIds(
        uint16 upLegendaryId_,
        uint16[] memory upRareIds_,
        uint16[] memory normalLegendaryIds_,
        uint16[] memory normalRareIds_,
        uint16[] memory normalCommonIds_
    ) external onlyOwner {
        upLegendaryId = upLegendaryId_;
        upRareIds = upRareIds_;
        normalLegendaryIds = normalLegendaryIds_;
        normalRareIds = normalRareIds_;
        normalCommonIds = normalCommonIds_;
    }

    function setDefaultRoleIdForNewUser(uint16 roleId_) external onlyOwner {
        defaultRoleIdForNewUser = roleId_;
    }

    /* upgradeable functions */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
