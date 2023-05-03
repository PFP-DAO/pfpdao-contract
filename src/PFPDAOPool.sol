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
    PFPDAO public pfpdao;

    uint16 public upLegendaryId;
    uint16[] public upRareIds;
    uint16[] public normalLegendaryIds;
    uint16[] public normalRareIds;
    uint16[] public normalCommonIds;

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

    function initialize(address equipmentAddress_, address roleNFTsAddress_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __PFPDAOPool_init();
        equipmentNFT = PFPDAOEquipment(equipmentAddress_);
        roleNFT = PFPDAORole(roleNFTsAddress_);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price,,,) = priceFeed.latestRoundData(); // price 96180000 == 0.9618 U
        return price;
    }

    // function mint(uint256 slot_) public payable {
    //     // int256 lastPrice = getLatestPrice();
    //     int256 lastPrice = 96180000; // 0.9618 U for mock
    //     uint256 shouldPay = uint256(priceLootOne * 1e18 / lastPrice);
    //     require(msg.value > shouldPay, "Not enough MATIC");
    //     uint256 tokenId = _createOriginalTokenId();
    //     ERC3525Upgradeable._mint(_msgSender(), tokenId, slot_, 1);
    // }

    function loot1() external payable {
        // 1. check price should in out
        int256 lastPrice = getLatestPrice();
        uint256 shouldPay = uint256(priceLootOne * 1e18 / lastPrice);
        require(msg.value > shouldPay, "Not enough MATIC");
        uint256 tmpSlot = _mintLogic(1);
        if (pfpdao.getRarity(tmpSlot) == 0) {
            equipmentNFT.mint(_msgSender(), tmpSlot, 1);
        } else {
            roleNFT.mint(_msgSender(), tmpSlot, 1);
        }
    }

    function loot10() external payable {
        // 1. check price should in out
        int256 lastPrice = getLatestPrice();
        uint256 shouldPay = uint256(priceLootTen * 1e18 / lastPrice);
        require(msg.value > shouldPay, "Not enough MATIC");

        uint8[] memory slots;
        uint8[] memory balance;

        for (uint8 i = 0; i < 10; i++) {
            uint256 tmpSlot = _mintLogic(i);
            // 2. check slot is not in slots
            bool isExist = false;
            for (uint8 j = 0; j < slots.length; j++) {
                if (slots[j] == tmpSlot) {
                    isExist = true;
                    balance[j] += 1;
                    break;
                }
            }
            unchecked {
                i += 1;
            }
        }
        require(slots.length == balance.length, "slots and balance length not equal");

        // 3. mint
        for (uint8 i = 0; i < slots.length; i++) {
            if (pfpdao.getRarity(slots[i]) == 0) {
                equipmentNFT.mint(_msgSender(), slots[i], balance[i]);
            } else {
                roleNFT.mint(_msgSender(), slots[i], balance[i]);
            }
        }
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
            if (seed % (normalLegendaryIds.length + 1) == 0) {
                roleId = upLegendaryId;
            } else {
                roleId = normalLegendaryIds[seed % normalLegendaryIds.length];
            }
            rarity = 2;
            mintTimesForSSS[_msgSender()] = 0;
        } else if (mintTimesForUpSS[_msgSender()] == 10) {
            // 10次保底
            if (seed % 4 == 0) {
                roleId = upRareIds[seed % upRareIds.length];
            } else {
                roleId = normalRareIds[seed % normalRareIds.length];
            }
            rarity = 1;
        } else {
            // 1% Legendary, 10% Rare, 89% Common
            rarity = uint8(seed % 100);
            if (rarity < 1) {
                if (seed % (normalLegendaryIds.length + 1) == 0) {
                    roleId = upLegendaryId;
                } else {
                    roleId = normalLegendaryIds[seed % normalLegendaryIds.length];
                }
                rarity = 2;
                mintTimesForSSS[_msgSender()] = 0;
                mintTimesForUpSS[_msgSender()] += 1;
            } else if (rarity < 11) {
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

        uint32 variant = getRoleVariant(_msgSender(), roleId);
        return pfpdao.generateSlot(roleId, rarity, variant, 1, 0);
    }

    /* admin functions */
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
