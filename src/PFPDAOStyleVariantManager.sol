// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IPFPDAOStyleVariantManager.sol";

contract PFPDAOStyleVariantManager is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IPFPDAOStyleVariantManager
{
    bytes32 public constant ALLOWED_CALLER_ROLE = keccak256("ALLOWED_CALLER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => mapping(uint16 => mapping(uint8 => uint32))) public addressToStyleVariant;
    mapping(uint16 => mapping(uint8 => uint32)) public lastStyleVariant;

    function initialize(address pool_, address role_) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ALLOWED_CALLER_ROLE, pool_);
        _setupRole(ALLOWED_CALLER_ROLE, role_);
    }

    modifier onlyAllowedCaller() {
        require(hasRole(ALLOWED_CALLER_ROLE, _msgSender()), "Caller is not allowed");
        _;
    }

    function grantAllowedCallerRole(address newCaller) public onlyRole(ADMIN_ROLE) {
        grantRole(ALLOWED_CALLER_ROLE, newCaller);
    }

    function setAddressToStyleVariant(address account, uint16 roleId, uint8 style, uint32 value)
        public
        onlyRole(ADMIN_ROLE)
    {
        addressToStyleVariant[account][roleId][style] = value;
        lastStyleVariant[roleId][style] = value;
    }

    function getRoleAwakenVariant(address account, uint16 roleId, uint8 style)
        public
        onlyAllowedCaller
        returns (uint32)
    {
        if (addressToStyleVariant[account][roleId][style] == 0) {
            lastStyleVariant[roleId][style] += 1;
            addressToStyleVariant[account][roleId][style] = lastStyleVariant[roleId][style];
        }
        return addressToStyleVariant[account][roleId][style];
    }

    function viewRoleAwakenVariant(address account, uint16 roleId, uint8 style) public view returns (uint32) {
        return addressToStyleVariant[account][roleId][style];
    }

    function viewLastVariant(uint16 roleId, uint8 style) public view returns (uint32) {
        return lastStyleVariant[roleId][style];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    uint256[50] private __gap;
}
