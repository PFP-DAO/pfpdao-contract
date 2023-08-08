// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Utils {
    function generateSlot(uint16 roleId_, uint8 rarity_, uint32 variant_, uint8 style_) public pure returns (uint256) {
        uint256 slot = uint256(roleId_) << 88;
        slot |= uint256(rarity_) << 80;
        slot |= uint256(variant_) << 48;
        slot |= uint256(style_) << 40;
        return slot;
    }

    function getAwaken(uint8 level_) public pure returns (uint256) {
        if (level_ < 20) return 0;
        if (level_ < 40) return 1;
        if (level_ < 60) return 2;
        if (level_ < 80) return 3;
        if (level_ < 90) return 4;
        return 5;
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

    /**
     * @dev new Role style start from 1
     */
    function getStyle(uint256 slot_) public pure returns (uint8) {
        return uint8((slot_ >> 40) & 0xFF);
    }

    /**
     * @dev uint32 for future use
     */
    function getReserved(uint256 slot_) public pure returns (uint32) {
        return uint32(slot_ >> 8 & 0xFFFFFFFF);
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

    function getSpecial(uint8 level_) public pure returns (uint256) {
        if (level_ < 20) return 0;
        if (level_ < 40) return 1;
        if (level_ < 80) return 5;
        if (level_ < 90) return 10;
        return 100;
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

    function cantLevelup(uint32 level_, uint32 exp_) public pure returns (bool) {
        if (level_ == 19 && exp_ == 56) return true;
        if (level_ == 39 && exp_ == 374) return true;
        if (level_ == 59 && exp_ == 2516) return true;
        if (level_ == 79 && exp_ == 16929) return true;
        if (level_ == 89 && exp_ == 43909) return true;

        return false;
    }
}
