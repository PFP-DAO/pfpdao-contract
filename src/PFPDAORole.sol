// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PFPDAO.sol";
import {PFPDAORoleVariantManager} from "./PFPDAORoleVariantManager.sol";

error InvalidSlot();

contract PFPDAORole is PFPDAO, PFPDAORoleVariantManager {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint32;
    using StringsUpgradeable for uint16;
    using StringsUpgradeable for uint8;

    mapping(uint16 => string) public roldIdToName;

    event LevelResult(uint256 indexed nftId, uint8 newLevel, uint32 newExp);

    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_) public initializer {
        __PFPDAO_init(name_, symbol_);
    }

    function airdrop(address[] calldata to_, uint16 roldId_, uint8 rariry_, uint8 level_) public onlyOwner {
        if (level_ >= 60) {
            revert InvalidSlot();
        }
        if (rariry_ > 2) {
            revert InvalidSlot();
        }
        if (bytes(roldIdToName[roldId_]).length == 0) {
            revert InvalidSlot();
        }
        for (uint256 i = 0; i < to_.length; i++) {
            uint32 variant = getRoleVariant(to_[i], roldId_);
            uint256 newSlot = generateSlot(roldId_, rariry_, variant, level_, 0);
            _mint(to_[i], newSlot, 1);
        }
    }

    function mint(address to_, uint256 slot_, uint256 balance_) public {
        // only active pool can mint
        require(activePools[msg.sender], "only active pool can mint");
        _mint(to_, slot_, balance_);
    }

    function levelUp(uint256 nftId_, uint32 addExp_) public returns (uint256) {
        uint256 oldSlot = slotOf(nftId_);
        (uint256 newSlot,) = addExp(oldSlot, addExp_);
        _burn(nftId_);
        _mint(msg.sender, nftId_, newSlot, 1);

        emit LevelResult(nftId_, getLevel(newSlot), getExp(newSlot));
        return newSlot;
    }

    function getStyle(uint256 slot_) public pure returns (uint8) {
        uint8 level = getLevel(slot_);
        return level < 20 ? 0 : level < 40 ? 1 : level < 60 ? 2 : level < 80 ? 3 : level < 90 ? 4 : 5;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        uint256 slot = slotOf(tokenId_);
        uint16 roleId = getRoleId(slot);
        string memory styleStr = getStyle(slot).toString();
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
}
