// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "erc-3525/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@chainlink/interfaces/AggregatorV3Interface.sol";

import "forge-std/console2.sol";

contract PFPDAO is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC3525Upgradeable, UUPSUpgradeable {
    uint32[89] public expTable;
    uint8[] public levelNeedAwakening;
    int256 public priceLootOne;
    int256 public priceLootTen;

    AggregatorV3Interface internal priceFeed;

    function __ERC3525BaseMock_init(string memory name_, string memory symbol_, uint8 decimals_)
        internal
        onlyInitializing
    {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC3525BaseMock_init_unchained(string memory, string memory, uint8) internal onlyInitializing {}

    constructor() {
        _disableInitializers();
    }

    function initialize(address oracle_) public initializer {
        __ERC3525BaseMock_init("PFPDAO", "PFP", 0);
        __Ownable_init();
        __UUPSUpgradeable_init();
        expTable = [
            10,
            11,
            12,
            13,
            15,
            16,
            18,
            19,
            21,
            24,
            26,
            29,
            31,
            35,
            38,
            42,
            46,
            51,
            56,
            61,
            67,
            74,
            81,
            90,
            98,
            108,
            119,
            131,
            144,
            159,
            174,
            192,
            211,
            232,
            255,
            281,
            309,
            340,
            374,
            411,
            453,
            498,
            548,
            602,
            663,
            729,
            802,
            882,
            970,
            1067,
            1174,
            1291,
            1420,
            1562,
            1719,
            1891,
            2080,
            2288,
            2516,
            2768,
            3045,
            3349,
            3684,
            4053,
            4458,
            4904,
            5394,
            5933,
            6527,
            7180,
            7897,
            8687,
            9556,
            10512,
            11563,
            12719,
            13991,
            15390,
            16929,
            18622,
            20484,
            22532,
            24786,
            27264,
            29991,
            32990,
            36289,
            39918,
            43909
        ];
        levelNeedAwakening = [20, 40, 60, 80, 90];
        // https://docs.chain.link/data-feeds/price-feeds/addresses/?network=polygon
        priceFeed = AggregatorV3Interface(oracle_);

        priceLootOne = 2.8e8; // 2.8 U
        priceLootTen = 22e8; // 22 U
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price,,,) = priceFeed.latestRoundData(); // price 96180000 == 0.9618 U
        return price;
    }

    function mint(uint256 slot_) public payable {
        // int256 lastPrice = getLatestPrice();
        int256 lastPrice = 96180000; // 0.9618 U for mock
        uint256 shouldPay = uint256(priceLootOne * 1e18 / lastPrice);
        require(msg.value > shouldPay, "Not enough MATIC");
        uint256 tokenId = _createOriginalTokenId();
        ERC3525Upgradeable._mint(_msgSender(), tokenId, slot_, 1);
    }

    function generateSlot(uint16 roleId_, uint8 rarity_, uint32 variant_, uint8 level_, uint32 exp_)
        public
        pure
        returns (uint256)
    {
        uint256 slot = uint256(roleId_) << 80;
        slot |= uint256(rarity_) << 72;
        slot |= uint256(variant_) << 40;
        slot |= uint256(level_) << 32;
        slot |= uint256(exp_);
        return slot;
    }

    function getRoleId(uint256 slot_) public pure returns (uint16) {
        return uint16((slot_ >> 80) & 0xFFFF);
    }

    function getRarity(uint256 slot_) public pure returns (uint8) {
        return uint8((slot_ >> 72) & 0xFF);
    }

    function getVariant(uint256 slot_) public pure returns (uint32) {
        uint32 variant = uint32((slot_ >> 40) & 0xFFFFFFFF);
        return variant;
    }

    function getLevel(uint256 slot_) public pure returns (uint8) {
        uint8 level = uint8((slot_ >> 32) & 0xFF);
        return level;
    }

    function getExp(uint256 slot_) public pure returns (uint32) {
        return uint32(slot_ & 0xFFFFFFFF);
    }

    /**
     * @dev Add exp then generate new slot, then reach levelNeedAwakening will stuck
     * @param slot_ Slot
     * @param exp_ Exp
     * @return newSlot New slot
     * @return overflowExp Overflow exp
     */
    function addExp(uint256 slot_, uint32 exp_) public view returns (uint256, uint32) {
        uint8 level = getLevel(slot_);
        uint32 exp = getExp(slot_);
        uint32 newExp = exp + exp_;
        uint8 newLevel = level;
        uint32 overflowExp = 0;

        while (newExp >= expTable[newLevel - 1]) {
            newExp -= expTable[newLevel - 1];
            overflowExp = newExp;
            newLevel++;

            for (uint256 i = 0; i < levelNeedAwakening.length; i++) {
                if (levelNeedAwakening[i] == newLevel) {
                    uint8 oldLevel = newLevel - 1;
                    uint32 needLevelExp = expTable[oldLevel - 1];
                    overflowExp = newExp;
                    return (
                        generateSlot(getRoleId(slot_), getRarity(slot_), getVariant(slot_), oldLevel, needLevelExp),
                        overflowExp
                    );
                }
            }
        }
        return (generateSlot(getRoleId(slot_), getRarity(slot_), getVariant(slot_), newLevel, newExp), 0);
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
