// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc-3525/periphery/ERC3525MetadataDescriptorUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PFPDAOEquipMetadataDescriptor is ERC3525MetadataDescriptorUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using Strings for uint256;

    constructor() payable initializer {
        __ERC3525MetadataDescriptor_init();
    }

    function _tokenName(uint256 tokenId_) internal pure override returns (string memory) {
        return string(abi.encodePacked("The Power of Chaos #", tokenId_.toString()));
    }

    function _tokenDescription(uint256 tokenId_) internal pure override returns (string memory) {
        return "PFPDAO equipment, add experience points to any role when burned.";
    }

    function _tokenImage(uint256 tokenId_) internal pure override returns (bytes memory) {
        return "https://pfpdao-0.4everland.store/equipment/avatar-equip.jpg";
    }

    /* upgrade functions */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}
