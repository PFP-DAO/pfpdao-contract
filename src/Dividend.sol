// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDividend.sol";

error NotAllowed();

contract Dividend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IDividend {
    mapping(uint16 => uint256) public roleIdPoolBalance; // 某个角色池的总余额

    mapping(uint16 => uint256) public captainRightDenominator; // 某个角色的总权重

    mapping(address => mapping(uint16 => uint256)) public addressCaptainRight; // 某个地址的某个角色的总权重

    mapping(address => mapping(uint16 => uint256)) public lastClaimedTimestamp; // 某地址对于某角色上一次claim的时间

    mapping(uint256 => mapping(address => mapping(uint16 => uint256))) public batchAddressCaptainRight; // 某天某地址某角色的权益

    mapping(uint256 => mapping(uint16 => uint256)) public batchCaptainRight; // 某天某角色的总权益

    mapping(uint256 => mapping(uint16 => uint256)) public batchRoleIdPoolBalance; // 某个角色池某批次的余额

    uint256 public batch;

    IERC20 public usdcAddress;

    mapping(address => bool) public allowPools;
    mapping(address => bool) public rolesContracts;

    bool public isPaused;

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

    function initialize(address erc20_, address initPool_, address initRole_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        batch = 1;
        usdcAddress = IERC20(erc20_);
        allowPools[initPool_] = true;
        rolesContracts[initRole_] = true;
    }

    function getClaimAmount(address user_, uint16 captainId_) public view returns (uint256) {
        uint256 roleBalanceTotal = batchRoleIdPoolBalance[batch][captainId_];
        uint256 roleTotalRightYesterday = batchCaptainRight[batch - 1][captainId_];
        uint256 captainRightYesterday = batchAddressCaptainRight[batch - 1][user_][captainId_];
        uint256 captainRightToday = batchAddressCaptainRight[batch][user_][captainId_];
        if (
            roleBalanceTotal == 0 || roleTotalRightYesterday == 0 || captainRightYesterday == 0 || captainRightToday > 0
        ) {
            return 0;
        }
        return roleBalanceTotal * captainRightYesterday / roleTotalRightYesterday;
    }

    function claim(address user_, uint16 captainId_) public onlyAllowPools {
        if (
            !isPaused && batchAddressCaptainRight[batch][user_][captainId_] == 0
                && addressCaptainRight[user_][captainId_] > 0
        ) {
            uint256 shouldPay = getClaimAmount(user_, captainId_);

            //然后读取当前addressCaptainWeight，修改今日batch的batchAddressCaptainRight和batchCaptainRight
            batchCaptainRight[batch][captainId_] += addressCaptainRight[user_][captainId_];
            batchAddressCaptainRight[batch][user_][captainId_] += addressCaptainRight[user_][captainId_];
            lastClaimedTimestamp[user_][captainId_] = block.timestamp;

            _transferDividendTo(user_, shouldPay, captainId_);
        }
    }

    function _transferDividendTo(address to_, uint256 amount_, uint16 roleId_) private {
        // transfer USDC amount to to_
        bool success = usdcAddress.transfer(to_, amount_);
        if (!success) {
            revert("transfer USDC failed");
        }
        emit Claim(to_, roleId_, amount_, batch);
    }

    function setCaptainRight(address user_, uint16 captainId_, uint256 newRight_) public onlyRoles {
        uint256 oldAddressCaptainRight = addressCaptainRight[user_][captainId_];
        addressCaptainRight[user_][captainId_] = newRight_;
        captainRightDenominator[captainId_] += (newRight_ - oldAddressCaptainRight);
    }

    function addCaptainRight(address user_, uint16 captainId_, uint256 addRight_) public onlyRoles {
        addressCaptainRight[user_][captainId_] += addRight_;
        captainRightDenominator[captainId_] += addRight_;
    }

    function transferCaptainRight(address from_, address to_, uint16 captainId_, uint256 right_) public onlyRoles {
        addressCaptainRight[from_][captainId_] -= right_;
        addressCaptainRight[to_][captainId_] += right_;
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

    function contribute(uint16 roleId, uint256 amount) external {
        bool success = usdcAddress.transferFrom(_msgSender(), address(this), amount);
        require(success, "contribute USDC failed");
        roleIdPoolBalance[roleId] += amount;
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
