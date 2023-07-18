// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPFPDAOStyleVariantManager {
    function getRoleAwakenVariant(address account, uint16 roleId, uint8 style) external returns (uint32);
}
