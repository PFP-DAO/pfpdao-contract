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

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
        if (from_ != address(0) && to_ != address(0)) {
            revert Soulbound();
        }
    }
}
