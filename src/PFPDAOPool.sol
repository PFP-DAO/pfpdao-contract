// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

import {PFPDAO} from "./PFPDAO.sol";
import {PFPDAORoleVariantManager} from "./PFPDAORoleVariantManager.sol";
import {PFPDAOEquipment} from "./PFPDAOEquipment.sol";
import {PFPDAORole} from "./PFPDAORole.sol";

// import "@chainlink/interfaces/AggregatorV3Interface.sol";

// import "forge-std/console2.sol";

// error FreeLooted(address);
error InvalidSignature();
error WhiteListUsed(uint8);
error InvaildLootTimes();

contract PFPDAOPool is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PFPDAORoleVariantManager
{
    using ECDSAUpgradeable for bytes32;
    using SignatureCheckerUpgradeable for address;

    int256 public priceLootOne;
    int256 public priceLootTen;

    mapping(address => uint8) public mintTimesForUpSS;
    mapping(address => uint8) public mintTimesForSSS;
    mapping(address => bool) public nextIsUpSSS;

    // AggregatorV3Interface internal _priceFeed;
    // address public oldAddressSlot;

    // When deploying the pool, the equipment address and the character NFT address should be specified.
    PFPDAOEquipment public equipmentNFT;
    PFPDAORole public roleNFT;

    uint16 public upLegendaryId;
    uint16[] public oldArraySlot;
    uint16[] public upRareIds;
    uint16[] public normalLegendaryIds;
    uint16[] public normalRareIds;
    uint16[] public normalCommonIds;

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

    // event SupportResult(address indexed user, uint16 indexed captainId, uint256 value);

    // function __PFPDAOPool_init() internal onlyInitializing {
    //     __PFPDAOPool_init_unchained();
    // }

    // function __PFPDAOPool_init_unchained() internal onlyInitializing {}

    constructor() {
        _disableInitializers();
    }

    function initialize(address equipmentAddress_, address roleNFTAddress_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        roleNFT = PFPDAORole(roleNFTAddress_);
        equipmentNFT = PFPDAOEquipment(equipmentAddress_);

        _defaultRoleIdForNewUser = 1;

        // https://docs.chain.link/data-feeds/price-feeds/addresses/?network=polygon
        // mainnet 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        // _priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        // priceLootOne = 2.8e8; // 2.8 U
        // priceLootTen = 22e8; // 22 U
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
        // (, int256 price,,,) = _priceFeed.latestRoundData();
        // return price;
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
            roleNFT.mint(_msgSender(), tmpSlot, 1);
            // console2.log("[loot1] role slot: %s, balance: %s", tmpSlot, 1);
        }

        emit LootResult(_msgSender(), tmpSlot, 1);
        emit GuarResult(
            _msgSender(), mintTimesForUpSS[_msgSender()], mintTimesForSSS[_msgSender()], nextIsUpSSS[_msgSender()]
            );
    }

    function loot1() external payable loot1PayVerify {
        roleIdPoolBalance[_defaultRoleIdForNewUser] += msg.value / 2;
        _loot1();
    }

    function loot1(uint16 captainId_, uint256 nftId_) external payable loot1PayVerify {
        roleIdPoolBalance[captainId_] += msg.value / 2;
        _loot1();
        roleNFT.levelUp(nftId_, 2);
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

        for (uint8 i = 0; i < balance.length; i++) {
            if (balance[i] == 0) continue;
            uint256 tmpSlot = slots[i];
            uint8 tmpBalance = balance[i];
            if (roleNFT.getRarity(slots[i]) == 0) {
                equipmentNFT.mint(_msgSender(), tmpSlot, tmpBalance);
                // console2.log("[loot10] equipment slot: %s, balance: %s", tmpSlot, tmpBalance);
            } else {
                roleNFT.mint(_msgSender(), tmpSlot, tmpBalance);
                // console2.log("[loot10] role slot: %s, balance: %s", tmpSlot, tmpBalance);
            }
            emit LootResult(_msgSender(), tmpSlot, tmpBalance);
        }

        emit GuarResult(
            _msgSender(), mintTimesForUpSS[_msgSender()], mintTimesForSSS[_msgSender()], nextIsUpSSS[_msgSender()]
            );
    }

    function loot10() external payable loot10PayVerify {
        roleIdPoolBalance[_defaultRoleIdForNewUser] += msg.value / 2;
        _lootN(10);
    }

    function loot10(uint16 captainId_, uint256 nftId_) external payable loot10PayVerify {
        roleIdPoolBalance[captainId_] += msg.value / 2;
        _lootN(10);
        roleNFT.levelUp(nftId_, 20);
    }

    function getGuarInfo(address user_) external view returns (uint8, uint8, bool) {
        return (mintTimesForUpSS[user_], mintTimesForSSS[user_], nextIsUpSSS[user_]);
    }

    function _mintLogic(uint8 time_) private returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, time_)));
        uint16 roleId;
        uint8 rarity;

        // Random number judgment. First check the legendary character guarantee, then the character guarantee, and finally the 10-draw guarantee.
        // 1. Legendary character guarantee: If a **Legendary** character is drawn and it is not the current up character, the next **Legendary** character drawn will definitely be the current up character.
        // 2. Character guarantee: Every 90 draws will definitely get a **Legendary** character.
        // 3. 10-draw guarantee: After 10 draws, there will definitely be a rare character. 3/4 of the time it will be the current up character, and 1/4 of the time it will be a permanent pool character.

        if (nextIsUpSSS[_msgSender()]) {
            // 角色大保底
            roleId = upLegendaryId;
            rarity = 2;
            nextIsUpSSS[_msgSender()] = false;
            mintTimesForSSS[_msgSender()] = 0;
            mintTimesForUpSS[_msgSender()] += 1;
        } else if (mintTimesForSSS[_msgSender()] == 89) {
            // Role guarantee: Every 90 draws will definitely get a Legendary character.
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
        } else if (mintTimesForUpSS[_msgSender()] == 9) {
            if (normalRareIds.length == 0) {
                roleId = upRareIds[seed % upRareIds.length];
            } else if (seed % 4 == 0) {
                roleId = upRareIds[seed % upRareIds.length];
            } else {
                roleId = normalRareIds[seed % normalRareIds.length];
            }
            rarity = 1;
            mintTimesForUpSS[_msgSender()] = 0;
            mintTimesForSSS[_msgSender()] += 1;
        } else {
            // 1% Legendary, 10% Rare, 89% Common
            uint8 randomValue = uint8(seed % 100);
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
    function setUpLegendaryId(uint16 upLegendaryId_) external onlyOwner {
        upLegendaryId = upLegendaryId_;
    }

    function setUpRareIds(uint16[] memory upRareIds_) external onlyOwner {
        upRareIds = new uint16[](upRareIds_.length);
        for (uint256 i = 0; i < upRareIds_.length; i++) {
            upRareIds[i] = upRareIds_[i];
        }
    }

    function setNormalLegendaryIds(uint16[] memory normalLegendaryIds_) external onlyOwner {
        normalLegendaryIds = new uint16[](normalLegendaryIds_.length);
        for (uint256 i = 0; i < normalLegendaryIds_.length; i++) {
            normalLegendaryIds[i] = normalLegendaryIds_[i];
        }
    }

    function setNormalRareIds(uint16[] memory normalRareIds_) external onlyOwner {
        normalRareIds = new uint16[](normalRareIds_.length);
        for (uint256 i = 0; i < normalRareIds_.length; i++) {
            normalRareIds[i] = normalRareIds_[i];
        }
    }

    function setNormalCommonIds(uint16[] memory normalCommonIds_) external onlyOwner {
        normalCommonIds = new uint16[](normalCommonIds_.length);
        for (uint256 i = 0; i < normalCommonIds_.length; i++) {
            normalCommonIds[i] = normalCommonIds_[i];
        }
    }

    function getUpRareIdsLength() external view returns (uint256) {
        return upRareIds.length;
    }

    function getNormalLegendaryIdsLength() external view returns (uint256) {
        return normalLegendaryIds.length;
    }

    function getNormalRareIdsLength() external view returns (uint256) {
        return normalRareIds.length;
    }

    function getNormalCommonIdsLength() external view returns (uint256) {
        return normalCommonIds.length;
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
