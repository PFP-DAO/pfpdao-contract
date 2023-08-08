// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "@uniswap/periphery/interfaces/IWETH.sol";
import "@uniswap/periphery/interfaces/IERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

import {PFPDAO} from "./PFPDAO.sol";
import {IPFPDAOStyleVariantManager} from "./IPFPDAOStyleVariantManager.sol";
import {PFPDAOEquipment} from "./PFPDAOEquipment.sol";
import {PFPDAORole} from "./PFPDAORole.sol";
import {IDividend} from "./IDividend.sol";
import {Utils} from "./libraries/Utils.sol";

error InvalidSignature();
error WhiteListUsed(uint8);
error InvaildLootTimes();
error USDCPaymentFailed();
error NotEnoughMATIC();

contract PFPDAOPool is Initializable, ContextUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using SignatureCheckerUpgradeable for address;

    // Replacing original variables from PFPDAORoleVariantManager with a storage gap of 52 slots
    uint256[49] private ___gap;

    AggregatorV3Interface internal dataFeed;
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
    mapping(uint16 => uint256) public oldRoleIdPoolBalance;
    uint16 _defaultRoleIdForNewUser; // deprecated

    mapping(address => bool) public oldFreeLooted; // deprecated
    mapping(address => uint8) public isWhitelistLooted;

    uint8 public activeNonce;
    address public signer;
    address public treasury;
    address public relayer;
    IUniswapV2Router02 public router;
    IWETH public weth;
    IERC20 public usdc;
    bool private _useNewPrice;

    event LootResult(address indexed user, uint256 slot, uint8 balance);
    event GuarResult(address indexed user, uint8 newSSGuar, uint8 newSSSGuar, bool isUpSSS);

    function initialize(address equipmentAddress_, address roleNFTAddress_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        roleNFT = PFPDAORole(roleNFTAddress_);
        equipmentNFT = PFPDAOEquipment(equipmentAddress_);
    }

    modifier loot1PayVerify(bool usdc_) {
        if (usdc_) {
            bool success = usdc.transferFrom(_msgSender(), address(this), uint256(priceLootOne));
            if (!success) revert USDCPaymentFailed();
        } else {
            int256 lastPrice = _useNewPrice ? int256(10 ** 8) : getLatestPrice();
            uint256 shouldPay = uint256(priceLootOne * int256(10 ** 20) / lastPrice);

            if (msg.value < shouldPay) revert NotEnoughMATIC();
        }
        _;
    }

    modifier loot10PayVerify(bool usdc_) {
        if (usdc_) {
            bool success = usdc.transferFrom(_msgSender(), address(this), uint256(priceLootTen));
            if (!success) revert USDCPaymentFailed();
        } else {
            int256 lastPrice = _useNewPrice ? int256(10 ** 8) : getLatestPrice();
            uint256 shouldPay = uint256((priceLootTen * 10 ** 20) / lastPrice);
            if (msg.value < shouldPay) revert NotEnoughMATIC();
        }
        _;
    }

    modifier onlyRelayer() {
        require(_msgSender() == relayer, "Only relayer");
        _;
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 answer,,,) = dataFeed.latestRoundData();
        return answer;
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

        if (Utils.getRarity(tmpSlot) == 0) {
            equipmentNFT.mint(_msgSender(), tmpSlot, 1);
        } else {
            roleNFT.mint(_msgSender(), tmpSlot);
        }

        emit LootResult(_msgSender(), tmpSlot, 1);
        emit GuarResult(
            _msgSender(), mintTimesForUpSS[_msgSender()], mintTimesForSSS[_msgSender()], nextIsUpSSS[_msgSender()]
        );
    }

    function loot1(bool usdc_) external payable loot1PayVerify(usdc_) {
        _loot1();
    }

    function loot1(uint16 captainId_, uint256 nftId_, bool usdc_) external payable loot1PayVerify(usdc_) {
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
            if (Utils.getRarity(slots[i]) == 0) {
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

    function loot10(bool usdc_) external payable loot10PayVerify(usdc_) {
        _lootN(10);
    }

    function loot10(uint16 captainId_, uint256 nftId_, bool usdc_) external payable loot10PayVerify(usdc_) {
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
        return Utils.generateSlot(roleId, rarity, variant, 1);
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

    function setUseNewPrice(bool useNewPrice_) external onlyOwner {
        _useNewPrice = useNewPrice_;
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

    function dailyDivide(uint16[] calldata roleIds, uint256[] calldata roleIdPoolBalanceToday_) external onlyRelayer {
        require(1 + upSSIds.length + nSSSIds.length + nSSIds.length == roleIds.length, "Need all roleIds");
        require(roleIds.length == roleIdPoolBalanceToday_.length, "RoleIds length isn't equal balance's");

        uint256 maticBalance = address(this).balance;
        if (maticBalance > 0) {
            _swapMaticToUSDC(maticBalance);
        }

        uint256 usdcBalance = usdc.balanceOf(address(this));
        if (usdcBalance > 0) {
            bool toDividendDone = usdc.transfer(address(dividend), usdcBalance / 2);
            bool toTreasuryDone = usdc.transfer(address(treasury), usdcBalance / 2);
            require(toDividendDone && toTreasuryDone, "USDC transfer failed");
        }

        uint256 activeBatch = dividend.batch();
        uint256 newBatch = activeBatch + 1;
        // roleIdPoolBalanceToday_总和 可能会比 usdcBalance/2 更大一点
        for (uint256 i = 0; i < roleIds.length; i++) {
            dividend.updateRoleIdPoolBalance(newBatch, roleIds[i], roleIdPoolBalanceToday_[i]);
        }
        dividend.setNewBatch();
    }

    function _swapMaticToUSDC(uint256 amount_) private {
        int256 lastPrice = getLatestPrice();
        uint256 amountOutMin = uint256(lastPrice) * amount_ * 95 / 10 ** 22; // 5% slippage
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdc);
        router.swapExactETHForTokens{value: amount_}(amountOutMin, path, address(this), block.timestamp + 5 minutes);
    }

    function setRelayer(address relayer_) external onlyOwner {
        relayer = relayer_;
    }

    function setSwapRouter(address router_) external onlyOwner {
        router = IUniswapV2Router02(router_);
    }

    function setWETH(address weth_) external onlyOwner {
        weth = IWETH(weth_);
    }

    function setUSDC(address usdc_) external onlyOwner {
        usdc = IERC20(usdc_);
    }

    function setFeed(address oracle_) external onlyOwner {
        dataFeed = AggregatorV3Interface(oracle_);
    }

    function setActiveNonce(uint8 nonce_) external onlyOwner {
        activeNonce = nonce_;
    }

    // withdraw eth
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        // payable(treasury).transfer(balance);
        (bool success,) = treasury.call{value: balance}("");
        require(success, "Transfer failed.");
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
