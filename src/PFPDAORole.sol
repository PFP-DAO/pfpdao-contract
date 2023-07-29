// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PFPDAO.sol";
import {IPFPDAOStyleVariantManager} from "./IPFPDAOStyleVariantManager.sol";
import {IDividend} from "./IDividend.sol";

import "forge-std/console2.sol";

error InvalidSlot();
error NotReachLimit(uint8);
error NotAllowed();
error NotOwner();

contract PFPDAORole is PFPDAO {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint32;
    using StringsUpgradeable for uint16;
    using StringsUpgradeable for uint8;

    IPFPDAOStyleVariantManager private styleVariantManager;

    mapping(uint16 => string) public roldIdToName;

    address public equipmentContract;

    struct Exp {
        uint8 level;
        uint32 exp;
    }

    mapping(uint256 => Exp) public exps;

    IDividend public dividend;

    event LevelResult(uint256 indexed nftId, uint8 newLevel, uint32 newExp);
    event AwakeResult(uint256 indexed nftId, uint32 oldVariant, uint32 newVariant, uint8 newStyle);

    function initialize(string calldata name_, string calldata symbol_) public initializer {
        __PFPDAO_init(name_, symbol_);
    }

    function airdrop(address[] calldata to_, uint16 roldId_, uint8 rarity_) public onlyOwner {
        for (uint256 i = 0; i < to_.length; i++) {
            uint32 variant = styleVariantManager.getRoleAwakenVariant(to_[i], roldId_, 1);
            uint256 newSlot = generateSlot(roldId_, rarity_, variant, 1);
            _mint(to_[i], newSlot, 1);
        }
    }

    function mint(address to_, uint256 slot_) public {
        if (!activePools[_msgSender()]) {
            revert NotAllowed();
        }
        uint256 tokenId = _mint(to_, slot_, 1);
        exps[tokenId].level = 1;
        exps[tokenId].exp = 0;
    }

    function getLevel(uint256 nftId_) public view returns (uint8) {
        return exps[nftId_].level == 0 ? 1 : exps[nftId_].level;
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

    function getSpecial(uint8 level_) public pure returns (uint256) {
        if (level_ < 20) return 0;
        if (level_ < 40) return 1;
        if (level_ < 80) return 5;
        if (level_ < 90) return 10;
        return 100;
    }

    function _addExp(uint256 nftId_, uint32 exp_) private view returns (uint8, uint8, uint32, uint32) {
        uint8 oldLevel = getLevel(nftId_);
        uint32 oldExp = getExp(nftId_);
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
                    return (oldLevel, tmpOldLevel, needLevelExp, overflowExp);
                }
            }
        }
        return (oldLevel, newLevel, newExp, 0);
    }

    function _levelUp(uint256 nftId_, uint32 addExp_) private returns (uint8, uint32, uint32) {
        (uint8 oldLevel, uint8 level, uint32 exp, uint32 overflowExp) = _addExp(nftId_, addExp_);
        exps[nftId_].level = level;
        exps[nftId_].exp = exp;
        emit LevelResult(nftId_, level, exp);
        if (level > 19 && level > oldLevel) {
            uint256 slot = slotOf(nftId_);
            uint16 roleId = getRoleId(slot);
            uint8 awakenLevel = getStyle(slot);
            uint256 newRight = (level - oldLevel) * (awakenLevel - 1) * getSpecial(level);
            dividend.addCaptainRight(_msgSender(), roleId, newRight);
        }
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

    function reachLimitLevel(uint256 nftId_) public view returns (bool) {
        uint32 level = getLevel(nftId_);
        uint32 exp = getExp(nftId_);

        if (level == 19 && exp == expTable[18]) return true;
        if (level == 39 && exp == expTable[38]) return true;
        if (level == 59 && exp == expTable[58]) return true;
        if (level == 79 && exp == expTable[78]) return true;
        if (level == 89 && exp == expTable[88]) return true;

        return false;
    }

    function generateSlotWhenAwake(uint256 oldSlot_, uint32 newVariant_) public pure returns (uint256) {
        uint8 oldStyle = getStyle(oldSlot_);
        uint256 slot = oldSlot_;

        uint256 VARIANT_MASK = uint256(0xFFFFFFFF) << 48;
        uint256 VARIANT_SHIFT = 48;
        uint256 STYLE_MASK = uint256(0xFF) << 40;
        uint256 STYLE_SHIFT = 40;
        uint256 VARIANT_OLDSTYLE_SHIFT = 88 + 32 * oldStyle;

        slot = (slot & ~VARIANT_MASK) | (uint256(newVariant_) << VARIANT_SHIFT);
        slot = (slot & ~STYLE_MASK) | (uint256(oldStyle + 1) << STYLE_SHIFT);
        slot |= uint256(getVariant(oldSlot_)) << VARIANT_OLDSTYLE_SHIFT;

        return slot;
    }

    function getVariants(uint256 slot_) public pure returns (uint32[] memory) {
        uint8 style = getStyle(slot_);
        uint256 variantCount = style - 1;
        uint32[] memory variants = new uint32[](variantCount);

        for (uint256 i = 0; i < variantCount; i++) {
            uint32 newVariant = uint32(slot_ >> (88 + 32 * (i + 1)) & 0xFFFFFFFF);
            variants[i] = newVariant;
        }
        return variants;
    }

    function awake(uint256 nftId_, uint256[] memory burnNftIds_) external returns (uint256) {
        uint256 nftMainSlot = slotOf(nftId_);
        uint16 mainRoleId = getRoleId(nftMainSlot);
        uint8 nftMainStyle = getStyle(nftMainSlot);

        require(burnNftIds_.length == 2 ** (nftMainStyle - 1), "Invalid burnNftIds length");

        for (uint256 i; i < burnNftIds_.length; i++) {
            uint256 burnNftId_ = burnNftIds_[i];
            if (ownerOf(burnNftId_) != _msgSender()) {
                revert NotOwner();
            }
            uint256 burnNftSlot_ = slotOf(burnNftId_);

            if (mainRoleId != getRoleId(burnNftSlot_)) {
                revert InvalidSlot();
            }
            _burn(burnNftId_);
        }

        if (!reachLimitLevel(nftId_)) {
            revert NotReachLimit(getLevel(nftId_));
        }

        uint32 oldVariant = getVariant(nftMainSlot);
        uint32 newVariant = styleVariantManager.getRoleAwakenVariant(_msgSender(), mainRoleId, nftMainStyle + 1);
        uint8 newStyle = nftMainStyle + 1;
        uint256 newSlot = generateSlotWhenAwake(nftMainSlot, newVariant);
        _burn(nftId_);
        _mint(_msgSender(), nftId_, newSlot, 1);

        uint8 oldLevel = getLevel(nftId_);
        uint8 newLevel = oldLevel + 1;
        _setLevel(nftId_, newLevel);
        _setExp(nftId_, 0);

        uint256 oldRight = getSpecial(oldLevel) * oldLevel * (nftMainStyle - 1);
        uint256 newRight = getSpecial(newLevel) * newLevel * (newStyle - 1);

        dividend.addCaptainRight(_msgSender(), mainRoleId, newRight - oldRight);

        emit AwakeResult(nftId_, oldVariant, newVariant, newStyle);
        return newSlot;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        uint256 slot = slotOf(tokenId_);
        uint16 roleId = getRoleId(slot);
        string memory roleIdStr = roleId.toString();
        string memory styleStr = (getStyle(slot) - 1).toString();
        return string(
            abi.encodePacked(
                "https://pfpdao-0.4everland.store/metadata/",
                roleIdStr,
                "/V1_",
                styleStr,
                "/role_",
                roleIdStr,
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

    function setStyleVariantManager(address variantManager_) public onlyOwner {
        styleVariantManager = IPFPDAOStyleVariantManager(variantManager_);
    }

    function setDividend(address dividend_) public onlyOwner {
        dividend = IDividend(dividend_);
    }

    function getAwaken(uint8 level_) public pure returns (uint256) {
        if (level_ < 20) return 0;
        if (level_ < 40) return 1;
        if (level_ < 60) return 2;
        if (level_ < 80) return 3;
        if (level_ < 90) return 4;
        return 5;
    }

    function setRoleLevelAndExp(uint256 nftId_, uint8 level_, uint32 exp_) public onlyOwner {
        uint8 oldLevel = getLevel(nftId_);
        _setLevel(nftId_, level_);
        _setExp(nftId_, exp_);

        if (level_ > 19 && level_ > oldLevel) {
            uint256 oldRight = getSpecial(oldLevel) * oldLevel * getAwaken(oldLevel);
            uint256 newRight = getSpecial(level_) * level_ * getAwaken(level_);
            dividend.addCaptainRight(ownerOf(nftId_), getRoleId(slotOf(nftId_)), newRight - oldRight);
        }
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
        uint8 level = getLevel(fromTokenId_);
        if (level < 60 && from_ != address(0) && to_ != address(0)) {
            revert Soulbound();
        }

        if (level > 59 && from_ != address(0) && to_ != address(0)) {
            uint256 rightToTransfer = getSpecial(level) * level * getAwaken(level);
            dividend.transferCaptainRight(from_, to_, getRoleId(slot_), rightToTransfer);
        }
    }
}
