// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PFPDAO.sol";
import {PFPDAORoleVariantManager} from "./PFPDAORoleVariantManager.sol";

error InvalidSlot();
error NotAllowed();
error NotOwner();

contract PFPDAORole is PFPDAO, PFPDAORoleVariantManager {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint32;
    using StringsUpgradeable for uint16;
    using StringsUpgradeable for uint8;

    mapping(uint16 => string) public roldIdToName;

    address public equipmentContract;

    struct Exp {
        uint8 level;
        uint32 exp;
    }

    mapping(uint256 => Exp) public exps;

    event LevelResult(uint256 indexed nftId, uint8 newLevel, uint32 newExp);
    event AwakeResult(uint256 indexed nftId, uint32 oldVariant, uint32 newVariant, uint8 newStyle);

    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_) public initializer {
        __PFPDAO_init(name_, symbol_);
    }

    function airdrop(address[] calldata to_, uint16 roldId_, uint8 rarity_, uint8 style_) public onlyOwner {
        if (style_ >= 4 || rarity_ == 0 || rarity_ > 2 || bytes(roldIdToName[roldId_]).length == 0) {
            revert InvalidSlot();
        }

        for (uint256 i = 0; i < to_.length; i++) {
            uint32 variant =
                rarity_ == 1 ? getRoleVariant(to_[i], roldId_) : getRoleAwakenVariant(to_[i], roldId_, style_);

            uint256 newSlot = generateSlot(roldId_, rarity_, variant, style_);
            _mint(to_[i], newSlot, 1);
        }
    }

    function mint(address to_, uint256 slot_) public {
        // only active pool can mint
        if (!activePools[_msgSender()]) {
            revert NotAllowed();
        }
        uint256 tokenId = _mint(to_, slot_, 1);
        exps[tokenId].level = 1;
        exps[tokenId].exp = 0;
    }

    function getLevel(uint256 nftId_) public view returns (uint8) {
        return exps[nftId_].level;
    }

    function _setLevel(uint256 nftId_, uint8 newLevel_) private {
        exps[nftId_].level = newLevel_;
    }

    function getExp(uint256 nftId_) public view returns (uint32) {
        return exps[nftId_].exp;
    }

    function _setExp(uint256 nftId_, uint32 newExp_) private {
        exps[nftId_].exp = newExp_;
    }

    function _addExp(uint256 nftid_, uint32 exp_) private view returns (uint8, uint32, uint32) {
        uint8 oldLevel = getLevel(nftid_);
        uint32 oldExp = getExp(nftid_);
        uint32 newExp = oldExp + exp_;
        uint8 newLevel = oldLevel;
        uint32 overflowExp = 0;

        while (newExp >= expTable[newLevel - 1]) {
            newExp -= expTable[newLevel - 1];
            overflowExp = newExp;
            newLevel++;

            for (uint256 i = 0; i < levelNeedAwakening.length; i++) {
                if (levelNeedAwakening[i] == newLevel) {
                    uint8 tmpOldLevel = newLevel - 1;
                    uint32 needLevelExp = expTable[tmpOldLevel - 1];
                    overflowExp = newExp;
                    return (tmpOldLevel, needLevelExp, overflowExp);
                }
            }
        }
        return (newLevel, newExp, 0);
    }

    function _levelUp(uint256 nftId_, uint32 addExp_) private returns (uint8, uint32, uint32) {
        (uint8 level, uint32 exp, uint32 overflowExp) = _addExp(nftId_, addExp_);
        exps[nftId_].level = level;
        exps[nftId_].exp = exp;
        emit LevelResult(nftId_, level, exp);
        return (level, exp, overflowExp);
    }

    function levelUpWhenLoot(uint256 nftId_, uint32 addExp_) public returns (uint8, uint32, uint32) {
        if (!activePools[_msgSender()]) {
            revert NotAllowed();
        }
        return _levelUp(nftId_, addExp_);
    }

    function levelUpByBurnEquipments(uint256 nftId_, uint256[] calldata equipmentIds)
        external
        returns (uint8, uint32, uint32)
    {
        require(equipmentIds.length > 0, "EquipmentIds is empty");
        if (ownerOf(nftId_) != _msgSender()) {
            revert NotOwner();
        }
        uint32 totalExp = 0;
        PFPDAO equip = PFPDAO(equipmentContract);
        for (uint256 i = 0; i < equipmentIds.length; i++) {
            if (equip.ownerOf(equipmentIds[i]) != _msgSender()) {
                revert NotOwner();
            }
            uint256 balance = equip.balanceOf(equipmentIds[i]);
            equip.burn(equipmentIds[i]);
            totalExp += 8 * uint32(balance);
        }
        return _levelUp(nftId_, totalExp);
    }

    function computeStyle(uint8 level_) public pure returns (uint8) {
        if (level_ < 20) {
            return 0;
        } else if (level_ < 40) {
            return 1;
        } else if (level_ < 60) {
            return 2;
        } else if (level_ < 80) {
            return 3;
        } else if (level_ < 90) {
            return 4;
        } else {
            return 5;
        }
    }

    function reachLimitLevel(uint256 nftId_) public view returns (bool) {
        uint32[] memory levels = new uint32[](5);
        levels[0] = 20 - 1;
        levels[1] = 40 - 1;
        levels[2] = 60 - 1;
        levels[3] = 80 - 1;
        levels[4] = 90 - 1;
        uint32 level = getLevel(nftId_);
        uint32 exp = getExp(nftId_);
        for (uint256 i = 0; i < levels.length; i++) {
            if (level == levels[i] && exp == expTable[levels[i] - 1]) {
                return true;
            }
        }
        return false;
    }

    function generateSlotWhenAwake(uint256 oldSlot_, uint32 newVariant_) public pure returns (uint256) {
        uint8 oldStyle = getStyle(oldSlot_);
        uint256 slot = oldSlot_;
        slot = (slot & ~(uint256(0xFFFFFFFF) << 48)) | (uint256(newVariant_) << 48); // cover old variant
        slot = (slot & ~(uint256(0xFF) << 40)) | (uint256(oldStyle + 1) << 40); // replace old style to style+1
        slot |= uint256(getVariant(oldSlot_)) << 88 + 32 * oldStyle; // save history variant
        return slot;
    }

    function getVariants(uint256 slot_) public pure returns (uint32[] memory) {
        uint8 style = getStyle(slot_);
        uint32[] memory variants = new uint32[](style - 1);

        for (uint256 i = 0; i < style - 1; i++) {
            uint32 newVariant = uint32(slot_ >> (88 + 32 * (i + 1)) & 0xFFFFFFFF);
            variants[i] = newVariant;
        }
        return variants;
    }

    function awake(uint256 nftId_, uint256 burnNftId_) external returns (uint256) {
        uint256 nftMainSlot = slotOf(nftId_);
        uint256 nftBurnSlot = slotOf(burnNftId_);

        if (!reachLimitLevel(nftId_)) {
            revert InvalidSlot();
        }

        uint8 nftMainStyle = getStyle(nftMainSlot);

        if (nftMainStyle != getStyle(nftBurnSlot) || getRoleId(nftMainSlot) != getRoleId(nftBurnSlot)) {
            revert InvalidSlot();
        }

        uint16 roldId = getRoleId(nftMainSlot);
        uint32 oldVariant = getVariant(nftMainSlot);
        uint32 newVariant = getRoleAwakenVariant(_msgSender(), roldId, nftMainStyle + 1);

        uint8 newStyle = getStyle(nftMainSlot) + 1;
        uint256 newSlot = generateSlotWhenAwake(nftMainSlot, newVariant);

        _burn(nftId_);
        _burn(burnNftId_);
        _mint(_msgSender(), nftId_, newSlot, 1);

        _setLevel(nftId_, getLevel(nftId_) + 1);
        _setExp(nftId_, 0);

        emit AwakeResult(nftId_, oldVariant, newVariant, newStyle);
        return newSlot;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        uint256 slot = slotOf(tokenId_);
        uint16 roleId = getRoleId(slot);
        string memory styleStr = (getStyle(slot) - 1).toString();
        return string(
            abi.encodePacked(
                "https://pfpdao-0.4everland.store/metadata/",
                roleId.toString(),
                "/V1_",
                styleStr,
                "/role_",
                roleId.toString(),
                "_V1_",
                styleStr,
                "_",
                getVariant(slot).toString(),
                "_",
                roldIdToName[roleId],
                ".json"
            )
        );
    }

    function setRoleName(uint16 roleId_, string calldata name_) public onlyOwner {
        roldIdToName[roleId_] = name_;
    }

    function setEquipmentContract(address equipmentContract_) public onlyOwner {
        equipmentContract = equipmentContract_;
    }

    function addRoleExp(uint256 nftId_, uint32 exp_) public onlyOwner returns (uint8, uint32, uint32) {
        return _levelUp(nftId_, exp_);
    }

    function setRoleExp(uint256 nftId_, uint8 level_, uint32 exp_) public onlyOwner {
        require(exps[nftId_].level != 0, "exps[nftId_].level is 0");
        exps[nftId_].level = level_;
        exps[nftId_].exp = exp_;
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
        if (getLevel(fromTokenId_) < 60 && from_ != address(0) && to_ != address(0)) {
            revert Soulbound();
        }
    }
}
