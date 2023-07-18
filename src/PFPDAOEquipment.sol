// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PFPDAO.sol";

contract PFPDAOEquipment is PFPDAO {
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __PFPDAO_init("PFPDAOEquipment", "PFPE");
    }

    function mint(address to_, uint256 slot_, uint256 balance_) public onlyActivePool returns (uint256) {
        return _mint(to_, slot_, balance_);
    }

    function _setMetadataDescriptor(address metadataDescriptor_) internal override {
        metadataDescriptor = IERC3525MetadataDescriptorUpgradeable(metadataDescriptor_);
        emit SetMetadataDescriptor(metadataDescriptor_);
    }

    function setMetadataDescriptor(address metadataDescriptor_) external onlyOwner {
        _setMetadataDescriptor(metadataDescriptor_);
    }
}
