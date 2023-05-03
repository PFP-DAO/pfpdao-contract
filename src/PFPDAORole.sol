// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PFPDAO.sol";

contract PFPDAORole is PFPDAO {
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_, address[] calldata addToPools_)
        public
        initializer
    {
        __PFPDAO_init(name_, symbol_);
        for (uint256 i = 0; i < addToPools_.length; i++) {
            activePools[addToPools_[i]] = true;
        }
    }

    function mint(address to_, uint256 slot_, uint256 balance_) public {
        // only active pool can mint
        require(activePools[msg.sender], "only active pool can mint");
        _mint(to_, slot_, balance_);
    }
}
