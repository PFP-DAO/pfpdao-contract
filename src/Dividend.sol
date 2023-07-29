// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDividend.sol";

import "forge-std/console2.sol";

error NotAllowed();

contract Dividend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IDividend {
    mapping(uint16 => uint256) public roleIdPoolBalance; // 某个角色池的总余额

    mapping(uint16 => uint256) public captainRightDenominator; // 某个角色的总权重

    mapping(address => mapping(uint16 => uint256)) public addressCaptainRight; // 某个地址的某个角色的总权重

    mapping(address => mapping(uint16 => uint256)) public lastClaimedTimestamp; // 某地址对于某角色上一次claim的时间

    mapping(uint256 => mapping(address => mapping(uint16 => uint256))) public batchAddressCaptainRight; // 某天某地址某角色的权益

    mapping(uint256 => mapping(uint16 => uint256)) public batchCaptainRight; // 某天某角色的权益

    mapping(uint256 => mapping(uint16 => uint256)) public batchRoleIdPoolBalance; // 某个角色池某批次的余额

    uint256 public batch;

    IERC20 public usdcAddress;

    mapping(address => bool) public allowPools;
    mapping(address => bool) public rolesContracts;

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

    function claim(address user_, uint16 captainId_) public onlyAllowPools {
        uint256 activeBatch = batch;
        uint256 lastBatch = activeBatch - 1;
        uint256 captainRightYesterday = batchAddressCaptainRight[lastBatch][user_][captainId_];
        if (captainRightYesterday > 0) {
            uint256 roleBalanceYesterday = batchRoleIdPoolBalance[lastBatch][captainId_];
            uint256 roleTotalRightYesterday = batchCaptainRight[lastBatch][captainId_];
            uint256 shouldPay = (roleBalanceYesterday * captainRightYesterday) / (roleTotalRightYesterday * 50);

            transferDividendTo(user_, shouldPay, captainId_);
        }
        if (addressCaptainRight[user_][captainId_] > 0) {
            //然后读取当前addressCaptainWeight，修改今日batch的batchAddressCaptainRight和batchCaptainRight
            batchAddressCaptainRight[activeBatch][user_][captainId_] += addressCaptainRight[user_][captainId_];
        }
    }

    function transferDividendTo(address to_, uint256 amount_, uint16 roleId_) private {
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

    /* upgrade functions */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
