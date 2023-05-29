// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "erc-3525/ERC3525Upgradeable.sol";

error IsNotOwner();
error Soulbound();

contract PFPDAO is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC3525Upgradeable, UUPSUpgradeable {
    uint32[89] public expTable;
    uint8[] public levelNeedAwakening;

    // approved pools
    mapping(address => bool) public activePools;

    modifier onlyActivePool() {
        require(activePools[msg.sender], "only active pool can mint");
        _;
    }

    function __PFPDAO_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC3525_init(name_, symbol_, 0);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __PFPDAO_init_unchained();
    }

    function __PFPDAO_init_unchained() internal onlyInitializing {
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
    }

    function generateSlot(uint16 roleId_, uint8 rarity_, uint32 variant_, uint8 level_, uint32 exp_)
        public
        pure
        returns (uint256)
    {
        uint256 slot = uint256(roleId_) << 88;
        slot |= uint256(rarity_) << 80;
        slot |= uint256(variant_) << 48;
        slot |= uint256(level_) << 40;
        slot |= uint256(exp_) << 8;
        return slot;
    }

    function getRoleId(uint256 slot_) public pure returns (uint16) {
        return uint16((slot_ >> 88) & 0xFFFF);
    }

    function getRarity(uint256 slot_) public pure returns (uint8) {
        return uint8((slot_ >> 80) & 0xFF);
    }

    function getVariant(uint256 slot_) public pure returns (uint32) {
        uint32 variant = uint32((slot_ >> 48) & 0xFFFFFFFF);
        return variant;
    }

    function getLevel(uint256 slot_) public pure returns (uint8) {
        uint8 level = uint8((slot_ >> 40) & 0xFF);
        return level;
    }

    function getExp(uint256 slot_) public pure returns (uint32) {
        return uint32(slot_ >> 8 & 0xFFFFFFFF);
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

    function isActivePool(address pool_) external view returns (bool) {
        return activePools[pool_];
    }

    /* admin functions */
    function addActivePool(address pool_) external onlyOwner {
        activePools[pool_] = true;
    }

    function removeActivePool(address pool_) external onlyOwner {
        activePools[pool_] = false;
    }

    /* upgrade functions */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
        if (getLevel(slot_) < 60 && from_ != address(0) && to_ != address(0)) {
            revert Soulbound();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
