// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract PFPDAORoleVariantManager is Initializable {
    mapping(address => mapping(uint16 => uint32)) public addressToVariant;
    mapping(uint16 => uint32) public lastVariant;

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

    uint256[50] private __gap;
}
