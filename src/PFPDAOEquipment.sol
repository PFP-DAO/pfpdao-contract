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

    function mint(address to_, uint256 slot_, uint256 balance_) public returns (uint256) {
        // only active pool can mint
        require(activePools[msg.sender], "only active pool can mint");
        return _mint(to_, slot_, balance_);
    }
}
