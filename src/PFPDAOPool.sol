// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

import {PFPDAO} from "./PFPDAO.sol";
import {IPFPDAOStyleVariantManager} from "./IPFPDAOStyleVariantManager.sol";
import {PFPDAOEquipment} from "./PFPDAOEquipment.sol";
import {PFPDAORole} from "./PFPDAORole.sol";
import {IDividend} from "./IDividend.sol";

error InvalidSignature();
error WhiteListUsed(uint8);
error InvaildLootTimes();

contract PFPDAOPool is Initializable, ContextUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using SignatureCheckerUpgradeable for address;

    // Replacing original variables from PFPDAORoleVariantManager with a storage gap of 52 slots
    uint256[50] private ___gap;

    IDividend public dividend;
    IPFPDAOStyleVariantManager private styleVariantManager;

    int256 public priceLootOne;
    int256 public priceLootTen;

    mapping(address => uint8) public mintTimesForUpSS;
    mapping(address => uint8) public mintTimesForSSS;
    mapping(address => bool) public nextIsUpSSS;

    // When deploying the pool, the equipment address and the character NFT address should be specified.
    PFPDAOEquipment public equipmentNFT;
    PFPDAORole public roleNFT;

    uint16 public upSSSId;
    uint16[] private __unusedArray;
    uint16[] public upSSIds;
    uint16[] public nSSSIds;
    uint16[] public nSSIds;
    uint16[] public nSIds;

    // 50% of the funds go into the pool associated with the character.
    mapping(uint16 => uint256) public roleIdPoolBalance;
    uint16 _defaultRoleIdForNewUser;

    mapping(address => bool) public oldFreeLooted;
    mapping(address => uint8) public isWhitelistLooted;

    uint8 public activeNonce;
    address public signer;
    address public treasury;

    event LootResult(address indexed user, uint256 slot, uint8 balance);
    event GuarResult(address indexed user, uint8 newSSGuar, uint8 newSSSGuar, bool isUpSSS);

    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(address equipmentAddress_, address roleNFTAddress_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        roleNFT = PFPDAORole(roleNFTAddress_);
        equipmentNFT = PFPDAOEquipment(equipmentAddress_);

        _defaultRoleIdForNewUser = 1;

        priceLootOne = 2.8e18;
        priceLootTen = 22e18;
    }

    modifier loot1PayVerify() {
        int256 lastPrice = getLatestPrice();
        uint256 shouldPay = uint256(priceLootOne / lastPrice);
        require(msg.value > shouldPay, "No enough MATIC");
        _;
    }

    modifier loot10PayVerify() {
        int256 lastPrice = getLatestPrice();
        uint256 shouldPay = uint256(priceLootTen / lastPrice);
        require(msg.value > shouldPay, "No enough MATIC");
        _;
    }

    function getLatestPrice() public pure returns (int256) {
        return 10000000; // price 100000000 == 1 U for mock
    }

    function whitelistLoot(uint8 time_, bytes calldata _signature) external {
        if (isWhitelistLooted[_msgSender()] == activeNonce) {
            revert WhiteListUsed(activeNonce);
        }
        if (time_ == 0 || time_ > 10) {
            revert InvaildLootTimes();
        }
        bytes32 digest = keccak256(abi.encodePacked(_msgSender(), time_, activeNonce)).toEthSignedMessageHash();
        if (!signer.isValidSignatureNow(digest, _signature)) {
            revert InvalidSignature();
        }
        if (time_ == 1) {
            _loot1();
        } else {
            _lootN(time_);
        }

        isWhitelistLooted[_msgSender()] = activeNonce;
    }

    function _loot1() private {
        uint256 tmpSlot = _mintLogic(1);

        if (equipmentNFT.getRarity(tmpSlot) == 0) {
            equipmentNFT.mint(_msgSender(), tmpSlot, 1);
            // console2.log("[loot1] equipment slot: %s, balance: %s", tmpSlot, 1);
        } else {
            roleNFT.mint(_msgSender(), tmpSlot);
            // console2.log("[loot1] role slot: %s, balance: %s", tmpSlot, 1);
        }

        emit LootResult(_msgSender(), tmpSlot, 1);
        emit GuarResult(
            _msgSender(), mintTimesForUpSS[_msgSender()], mintTimesForSSS[_msgSender()], nextIsUpSSS[_msgSender()]
        );
    }

    function loot1() external payable loot1PayVerify {
        _loot1();
    }

    function loot1(uint16 captainId_, uint256 nftId_) external payable loot1PayVerify {
        dividend.claim(_msgSender(), captainId_);
        _loot1();
        roleNFT.levelUpWhenLoot(nftId_, 2);
    }

    function _lootN(uint8 time_) private {
        uint256[] memory slots = new uint256[](time_);
        uint8[] memory balance = new uint8[](time_);

        for (uint8 i = 0; i < time_; i++) {
            uint256 tmpSlot = _mintLogic(i);
            bool found = false;
            for (uint8 j = 0; j < slots.length; j++) {
                if (slots[j] == tmpSlot) {
                    balance[j]++;
                    found = true;
                    break;
                }
            }
            if (!found) {
                slots[i] = tmpSlot;
                balance[i] = 1;
            }
        }

        for (uint256 i = 0; i < balance.length; i++) {
            if (balance[i] == 0) continue;
            uint256 tmpSlot = slots[i];
            uint8 tmpBalance = balance[i];
            if (roleNFT.getRarity(slots[i]) == 0) {
                equipmentNFT.mint(_msgSender(), tmpSlot, tmpBalance);
            } else {
                roleNFT.mint(_msgSender(), tmpSlot);
            }
            emit LootResult(_msgSender(), tmpSlot, tmpBalance);
        }

        emit GuarResult(
            _msgSender(), mintTimesForUpSS[_msgSender()], mintTimesForSSS[_msgSender()], nextIsUpSSS[_msgSender()]
        );
    }

    function loot10() external payable loot10PayVerify {
        _lootN(10);
    }

    function loot10(uint16 captainId_, uint256 nftId_) external payable loot10PayVerify {
        dividend.claim(_msgSender(), captainId_);
        _lootN(10);
        roleNFT.levelUpWhenLoot(nftId_, 20);
    }

    function getGuarInfo(address user_) external view returns (uint8, uint8, bool) {
        return (mintTimesForUpSS[user_], mintTimesForSSS[user_], nextIsUpSSS[user_]);
    }

    function _mintLogic(uint8 time_) private returns (uint256) {
        uint16 roleId = 0;
        uint8 rarity = 0;
        uint256 upSSCount = upSSIds.length;
        uint256 cSSSCount = nSSSIds.length;
        uint256 nSSCount = nSSIds.length;

        uint256 seed = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, time_)));
        // Random number judgment. First check the legendary character guarantee, then the character guarantee, and finally the 10-draw guarantee.
        // 1. Legendary character guarantee: If a **Legendary** character is drawn and it is not the current up character, the next **Legendary** character drawn will definitely be the current up character.
        // 2. Character guarantee: Every 90 draws will definitely get a **Legendary** character.
        // 3. 10-draw guarantee: After 10 draws, there will definitely be a rare character. 3/4 of the time it will be the current up character, and 1/4 of the time it will be a permanent pool character.

        unchecked {
            if (nextIsUpSSS[_msgSender()]) {
                // 角色大保底
                roleId = upSSSId;
                rarity = 2;
                nextIsUpSSS[_msgSender()] = false;
                mintTimesForSSS[_msgSender()] = 0;
                mintTimesForUpSS[_msgSender()] += 1;
            } else if (mintTimesForSSS[_msgSender()] == 89) {
                // Role guarantee: Every 90 draws will definitely get a Legendary character.
                if (cSSSCount == 0) {
                    roleId = upSSSId;
                } else if (seed % (cSSSCount + 1) == 0) {
                    roleId = upSSSId;
                } else {
                    roleId = nSSSIds[seed % cSSSCount];
                }
                rarity = 2;
                mintTimesForSSS[_msgSender()] = 0;
                mintTimesForUpSS[_msgSender()] += 1;
            } else if (mintTimesForUpSS[_msgSender()] == 9) {
                if (nSSCount == 0) {
                    roleId = upSSIds[seed % upSSCount];
                } else if (seed % 4 == 0) {
                    roleId = upSSIds[seed % upSSCount];
                } else {
                    roleId = nSSIds[seed % nSSCount];
                }
                rarity = 1;
                mintTimesForUpSS[_msgSender()] = 0;
                mintTimesForSSS[_msgSender()] += 1;
            } else {
                // 1% Legendary, 10% Rare, 89% Common
                uint8 randomValue = uint8(seed % 100);
                if (randomValue < 1) {
                    if (cSSSCount == 0) {
                        roleId = upSSSId;
                    } else if (seed % (cSSSCount + 1) == 0) {
                        roleId = upSSSId;
                    } else {
                        roleId = nSSSIds[seed % cSSSCount];
                    }
                    rarity = 2;
                    mintTimesForSSS[_msgSender()] = 0;
                    mintTimesForUpSS[_msgSender()] += 1;
                } else if (randomValue < 11) {
                    if (seed % (upSSCount + nSSCount) <= upSSCount) {
                        roleId = upSSIds[seed % upSSCount];
                    } else {
                        roleId = nSSIds[seed % nSSCount];
                    }
                    rarity = 1;
                    mintTimesForSSS[_msgSender()] += 1;
                    mintTimesForUpSS[_msgSender()] = 0;
                } else {
                    mintTimesForSSS[_msgSender()] += 1;
                    mintTimesForUpSS[_msgSender()] += 1;
                }
            }
        }
        uint32 variant = 0;
        if (rarity != 0) {
            variant = styleVariantManager.getRoleAwakenVariant(_msgSender(), roleId, 1);
        }
        return roleNFT.generateSlot(roleId, rarity, variant, 1);
    }

    /* admin functions */
    function setupSSSId(uint16 upSSSId_) external onlyOwner {
        upSSSId = upSSSId_;
    }

    function setupSSIds(uint16[] memory upSSIds_) external onlyOwner {
        upSSIds = new uint16[](upSSIds_.length);
        for (uint256 i = 0; i < upSSIds_.length; i++) {
            upSSIds[i] = upSSIds_[i];
        }
    }

    function setnSSSIds(uint16[] memory nSSSIds_) external onlyOwner {
        nSSSIds = new uint16[](nSSSIds_.length);
        for (uint256 i = 0; i < nSSSIds_.length; i++) {
            nSSSIds[i] = nSSSIds_[i];
        }
    }

    function setnSSIds(uint16[] memory nSSIds_) external onlyOwner {
        nSSIds = new uint16[](nSSIds_.length);
        for (uint256 i = 0; i < nSSIds_.length; i++) {
            nSSIds[i] = nSSIds_[i];
        }
    }

    function setnSIds(uint16[] memory nSIds_) external onlyOwner {
        nSIds = new uint16[](nSIds_.length);
        for (uint256 i = 0; i < nSIds_.length; i++) {
            nSIds[i] = nSIds_[i];
        }
    }

    function getupSSIdsLength() external view returns (uint256) {
        return upSSIds.length;
    }

    function getnSSSIdsLength() external view returns (uint256) {
        return nSSSIds.length;
    }

    function getnSSIdsLength() external view returns (uint256) {
        return nSSIds.length;
    }

    function getnSIdsLength() external view returns (uint256) {
        return nSIds.length;
    }

    function defaultCaptainIdForNewUser() external view returns (uint16) {
        return _defaultRoleIdForNewUser;
    }

    function setDefaultRoleIdForNewUser(uint16 roleId_) external onlyOwner {
        _defaultRoleIdForNewUser = roleId_;
    }

    function setActiveNonce(uint8 nonce_) external onlyOwner {
        activeNonce = nonce_;
    }

    // withdraw eth
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(treasury).transfer(balance);
    }

    // set treasury
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function setPriceLootOne(int256 price_) external onlyOwner {
        priceLootOne = price_;
    }

    function setPriceLootTen(int256 price_) external onlyOwner {
        priceLootTen = price_;
    }

    function setStyleVariantManager(address variantManager_) external onlyOwner {
        styleVariantManager = IPFPDAOStyleVariantManager(variantManager_);
    }

    function setDividend(address dividend_) external onlyOwner {
        dividend = IDividend(dividend_);
    }

    /* upgradeable functions */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
