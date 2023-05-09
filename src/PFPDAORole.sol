// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PFPDAO.sol";

contract PFPDAORole is PFPDAO {
    event LevelResult(uint256 indexed nftId, uint8 newLevel, uint32 newExp);

    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_) public initializer {
        __PFPDAO_init(name_, symbol_);
    }

    function mint(address to_, uint256 slot_, uint256 balance_) public {
        // only active pool can mint
        require(activePools[msg.sender], "only active pool can mint");
        _mint(to_, slot_, balance_);
    }

    function levelUp(uint256 nftId_, uint32 addExp_) public returns (uint256) {
        uint256 oldSlot = slotOf(nftId_);
        (uint256 newSlot,) = addExp(oldSlot, addExp_);
        _burn(nftId_);
        _mint(msg.sender, nftId_, newSlot, 1);

        emit LevelResult(nftId_, getLevel(newSlot), getExp(newSlot));
        return newSlot;
    }
}
