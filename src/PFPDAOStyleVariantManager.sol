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

    modifier onlyAllowedCaller() {
        require(hasRole(ALLOWED_CALLER_ROLE, _msgSender()), "Caller is not allowed");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address pool_, address role_) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ALLOWED_CALLER_ROLE, pool_);
        _setupRole(ALLOWED_CALLER_ROLE, role_);
    }

    /// @notice Returns the variant of a character's image for a given address, role, and style.
    ///         Each address can only have a fixed character variant (image) per role and style.
    ///         The function increments the variant counter and assigns it to the address if not already assigned.
    /// @dev Can only be called by allowed callers (e.g., loot, awake, or airdrop contracts).
    /// @param account_ The user's address for which to get the variant.
    /// @param roleId_ The role ID of the character.
    /// @param style_ The art style associated with the character's awaken level.
    /// @return The variant of the character's image for the given address, role, and style.
    function getRoleAwakenVariant(address account_, uint16 roleId_, uint8 style_)
        public
        onlyAllowedCaller
        returns (uint32)
    {
        if (addressToStyleVariant[account_][roleId_][style_] == 0) {
            lastStyleVariant[roleId_][style_] += 1;
            addressToStyleVariant[account_][roleId_][style_] = lastStyleVariant[roleId_][style_];
        }
        return addressToStyleVariant[account_][roleId_][style_];
    }

    function viewRoleAwakenVariant(address account_, uint16 roleId_, uint8 style_) public view returns (uint32) {
        return addressToStyleVariant[account_][roleId_][style_];
    }

    function viewLastVariant(uint16 roleId_, uint8 style_) public view returns (uint32) {
        return lastStyleVariant[roleId_][style_];
    }

    /* admin functions */
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

    /* upgrade functions */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    uint256[50] private __gap;
}
