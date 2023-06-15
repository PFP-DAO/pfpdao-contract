// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract PFPDAORoleVariantManager is Initializable {
    mapping(address => mapping(uint16 => uint32)) public addressToVariant;
    mapping(uint16 => uint32) public lastVariant;
    mapping(address => mapping(uint16 => mapping(uint8 => uint32))) public addressToStyleVariant;
    mapping(uint16 => mapping(uint8 => uint32)) public lastStyleVariant;

    function __PFPDAORoleVariantManager_init() internal onlyInitializing {
        __PFPDAORoleVariantManager_init_unchained();
    }

    function __PFPDAORoleVariantManager_init_unchained() internal onlyInitializing {}

    function getRoleVariant(address account, uint16 roleId) internal returns (uint32) {
        if (addressToVariant[account][roleId] == 0) {
            lastVariant[roleId] += 1;
            addressToVariant[account][roleId] = lastVariant[roleId];
        }
        return addressToVariant[account][roleId];
    }

    function getRoleAwakenVariant(address account, uint16 roleId, uint8 style) internal returns (uint32) {
        if (addressToStyleVariant[account][roleId][style] == 0) {
            lastStyleVariant[roleId][style] += 1;
            addressToStyleVariant[account][roleId][style] = lastStyleVariant[roleId][style];
        }
        return addressToStyleVariant[account][roleId][style];
    }

    uint256[50] private __gap;
}
