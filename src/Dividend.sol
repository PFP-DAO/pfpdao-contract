// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDividend.sol";

error NotAllowed();

contract Dividend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IDividend {
    mapping(uint16 => uint256) public roleIdPoolBalance; // Total balance of a role pool

    mapping(uint16 => uint256) public captainRightDenominator; // Total weight of a role

    mapping(address => mapping(uint16 => uint256)) public addressCaptainRight; // Total weight of a role for a specific address

    mapping(address => mapping(uint16 => uint256)) public lastClaimedTimestamp; // Last claimed timestamp for a role by an address

    mapping(uint256 => mapping(address => mapping(uint16 => uint256))) public batchAddressCaptainRight; // Rights of a role for an address on a specific day

    mapping(uint256 => mapping(uint16 => uint256)) public batchCaptainRight; // Total rights of a role on a specific day

    mapping(uint256 => mapping(uint16 => uint256)) public batchRoleIdPoolBalance; // Balance of a role pool for a specific batch

    uint256 public batch;

    IERC20 public usdcAddress;

    mapping(address => bool) public allowPools;
    mapping(address => bool) public rolesContracts;

    bool public isPaused;

    mapping(uint256 => mapping(address => mapping(uint16 => bool))) public hasClaimed;

    event Claim(address indexed user, uint16 indexed roleId, uint256 amount, uint256 batch);

    modifier onlyAllowPools() {
        if (!allowPools[_msgSender()]) {
            revert NotAllowed();
        }
        _;
    }

    modifier onlyRoles() {
        if (!rolesContracts[_msgSender()]) {
            revert NotAllowed();
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address erc20_, address initPool_, address initRole_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        batch = 1;
        usdcAddress = IERC20(erc20_);
        allowPools[initPool_] = true;
        rolesContracts[initRole_] = true;
    }

    /* external functions */
    /// @notice contribute USDC to a role pool
    /// @param roleId_ captain id to support
    /// @param amount_ amount of USDC, need approve first
    function contribute(uint16 roleId_, uint256 amount_) external {
        bool success = usdcAddress.transferFrom(_msgSender(), address(this), amount_);
        require(success, "contribute USDC failed");
        roleIdPoolBalance[roleId_] += amount_;
    }

    /* public functions */
    function claim(address user_, uint16 captainId_) public onlyAllowPools {
        if (isPaused) return;
        uint256 batch_ = batch;
        uint256 captainRight = addressCaptainRight[user_][captainId_];
        uint256 captainRightForTomorrow = batchAddressCaptainRight[batch_][user_][captainId_];

        // captainRight may change between multiple loots in a batch, so update the difference
        if (captainRight > captainRightForTomorrow) {
            uint256 increment = captainRight - captainRightForTomorrow;
            batchCaptainRight[batch_][captainId_] += increment;
            batchAddressCaptainRight[batch_][user_][captainId_] += increment;
        }

        // seperate the right setting tomorrow and claim dividend today
        if (hasClaimed[batch_][user_][captainId_]) return;
        uint256 shouldPay = getClaimAmount(user_, captainId_);
        if (shouldPay > 0) {
            lastClaimedTimestamp[user_][captainId_] = block.timestamp;
            hasClaimed[batch_][user_][captainId_] = true;
            _transferDividendTo(user_, shouldPay, captainId_);
        }
    }

    function addCaptainRight(address user_, uint16 captainId_, uint256 addRight_) public onlyRoles {
        addressCaptainRight[user_][captainId_] += addRight_;
        captainRightDenominator[captainId_] += addRight_;
    }

    function transferCaptainRight(address from_, address to_, uint16 captainId_, uint256 right_) public onlyRoles {
        uint256 batch_ = batch;
        addressCaptainRight[from_][captainId_] -= right_;
        if (batchAddressCaptainRight[batch_][from_][captainId_] > 0) {
            batchAddressCaptainRight[batch_][from_][captainId_] -= right_;
        }
        addressCaptainRight[to_][captainId_] += right_;
    }

    function updateRoleIdPoolBalance(uint256 batch_, uint16 captainId_, uint256 newIncome_) public onlyAllowPools {
        require(batch_ > 0, "batch must > 0");
        // last batch remain
        uint256 remainLastBatch = batchRoleIdPoolBalance[batch_ - 1][captainId_];
        // add roleIdPoolBalance
        roleIdPoolBalance[captainId_] += (newIncome_ + remainLastBatch);
        // set 2% to batchRoleIdPoolBalance
        batchRoleIdPoolBalance[batch_][captainId_] = roleIdPoolBalance[captainId_] / 50;
        // set remain to roleIdPoolBalance
        roleIdPoolBalance[captainId_] -= batchRoleIdPoolBalance[batch_][captainId_];
    }

    function setNewBatch() public onlyAllowPools {
        batch += 1;
    }

    function getClaimAmount(address user_, uint16 captainId_) public view returns (uint256) {
        uint256 batch_ = batch;
        uint256 roleBalanceTotal = batchRoleIdPoolBalance[batch_][captainId_];
        uint256 roleTotalRightYesterday = batchCaptainRight[batch_ - 1][captainId_];
        uint256 captainRightYesterday = batchAddressCaptainRight[batch_ - 1][user_][captainId_];
        if (roleTotalRightYesterday == 0) {
            return 0;
        }
        return roleBalanceTotal * captainRightYesterday / roleTotalRightYesterday;
    }

    function getRightByRole(address user_, uint16 captainId_) public view returns (uint256) {
        uint256 roleRight = addressCaptainRight[user_][captainId_];
        uint256 totalRoleRight = captainRightDenominator[captainId_];
        if (roleRight == 0 || totalRoleRight == 0) {
            return 0;
        } else {
            return roleRight * 10000 / totalRoleRight;
        }
    }

    function getLastLootTimestamp(address user_, uint16 captainId_) public view returns (uint256) {
        return lastClaimedTimestamp[user_][captainId_];
    }

    /* private functions */
    function _transferDividendTo(address to_, uint256 amount_, uint16 roleId_) private {
        // transfer USDC amount to to_
        bool success = usdcAddress.transfer(to_, amount_);
        if (!success) {
            revert("transfer USDC failed");
        }
        emit Claim(to_, roleId_, amount_, batch);
    }

    /* admin functions */
    function setCaptainRight(address user_, uint16 captainId_, uint256 newRight_) external onlyOwner {
        uint256 oldAddressCaptainRight = addressCaptainRight[user_][captainId_];
        addressCaptainRight[user_][captainId_] = newRight_;
        captainRightDenominator[captainId_] += (newRight_ - oldAddressCaptainRight);
    }

    function setPause(bool pause_) external onlyOwner {
        isPaused = pause_;
    }

    /* upgrade functions */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
