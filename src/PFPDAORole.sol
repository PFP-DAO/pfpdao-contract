// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PFPDAO.sol";
import {Utils} from "./libraries/Utils.sol";
import {IPFPDAOStyleVariantManager} from "./IPFPDAOStyleVariantManager.sol";
import {IDividend} from "./IDividend.sol";

error InvalidSlot();
error NotReachLimit(uint8);
error NotAllowed();
error NotOwner();
error InvalidLength();

contract PFPDAORole is PFPDAO {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint32;
    using StringsUpgradeable for uint16;
    using StringsUpgradeable for uint8;

    IPFPDAOStyleVariantManager public styleVariantManager;

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
            uint256 newSlot = Utils.generateSlot(roldId_, rarity_, variant, 1);
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

    function getExp(uint256 nftId_) public view returns (uint32) {
        return exps[nftId_].exp;
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
            uint256 newRight = (level - oldLevel) * (Utils.getStyle(slot) - 1) * Utils.getSpecial(level);
            dividend.addCaptainRight(_msgSender(), Utils.getRoleId(slot), newRight);
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
        if (equipmentIds.length == 0) {
            revert InvalidLength();
        }
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

    function awake(uint256 nftId_, uint256[] memory burnNftIds_) external returns (uint256) {
        uint256 slot = slotOf(nftId_);
        uint16 roleId = Utils.getRoleId(slot);
        uint8 style = Utils.getStyle(slot);
        uint8 level = getLevel(nftId_);
        uint32 exp = getExp(nftId_);

        if (burnNftIds_.length != 2 ** (style - 1)) {
            revert InvalidLength();
        }

        for (uint256 i; i < burnNftIds_.length; i++) {
            uint256 toBurnId = burnNftIds_[i];
            if (ownerOf(toBurnId) != _msgSender()) {
                revert NotOwner();
            }
            uint256 burnNftSlot_ = slotOf(toBurnId);

            if (roleId != Utils.getRoleId(burnNftSlot_)) {
                revert InvalidSlot();
            }
            _burn(toBurnId);
        }

        if (!Utils.cantLevelup(level, exp)) {
            revert NotReachLimit(level);
        }

        uint32 newVariant = styleVariantManager.getRoleAwakenVariant(_msgSender(), roleId, style + 1);
        uint256 newSlot = Utils.generateSlotWhenAwake(slot, newVariant);
        _burn(nftId_);
        _mint(_msgSender(), nftId_, newSlot, 1);

        uint8 newLevel = level + 1;
        exps[nftId_].level = newLevel;
        exps[nftId_].exp = 0;

        dividend.addCaptainRight(
            _msgSender(),
            roleId,
            Utils.getSpecial(newLevel) * newLevel * style - Utils.getSpecial(level) * level * (style - 1)
        );

        emit AwakeResult(nftId_, Utils.getVariant(slot), newVariant, style + 1);
        return newSlot;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        uint256 slot = slotOf(tokenId_);
        uint16 roleId = Utils.getRoleId(slot);
        string memory roleIdStr = roleId.toString();
        string memory styleStr = (Utils.getStyle(slot) - 1).toString();
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
                Utils.getVariant(slot).toString(),
                "_",
                roldIdToName[roleId],
                ".json"
            )
        );
    }

    function setRoleName(uint16 roleId_, string calldata name_) public onlyOwner {
        roldIdToName[roleId_] = name_;
    }

    function setDividend(address dividend_) public onlyOwner {
        dividend = IDividend(dividend_);
    }

    function setEquipmentContract(address equipmentContract_) public onlyOwner {
        equipmentContract = equipmentContract_;
    }

    function setStyleVariantManager(address variantManager_) public onlyOwner {
        styleVariantManager = IPFPDAOStyleVariantManager(variantManager_);
    }

    function setRoleLevelAndExp(uint256 nftId_, uint8 level_, uint32 exp_) public onlyOwner {
        uint8 oldLevel = getLevel(nftId_);
        exps[nftId_].level = level_;
        exps[nftId_].exp = exp_;

        if (level_ > 19 && level_ > oldLevel) {
            uint256 oldRight = Utils.getSpecial(oldLevel) * oldLevel * Utils.getAwaken(oldLevel);
            uint256 newRight = Utils.getSpecial(level_) * level_ * Utils.getAwaken(level_);
            dividend.addCaptainRight(ownerOf(nftId_), Utils.getRoleId(slotOf(nftId_)), newRight - oldRight);
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
        if (from_ != address(0) && to_ != address(0)) {
            if (level < 60) {
                revert Soulbound();
            } else {
                uint256 rightToTransfer = Utils.getSpecial(level) * level * Utils.getAwaken(level);
                dividend.transferCaptainRight(from_, to_, Utils.getRoleId(slot_), rightToTransfer);
            }
        }
    }
}
