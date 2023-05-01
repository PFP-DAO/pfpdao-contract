// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "erc-3525/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract PFPDAO is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC3525Upgradeable, UUPSUpgradeable {

    // mappings from tokenId to address

    function __ERC3525BaseMock_init(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC3525BaseMock_init_unchained(string memory, string memory, uint8) internal onlyInitializing {
    }

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC3525BaseMock_init("PFPDAO","PFP",0);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function mint(
        uint256 slot_
    ) public virtual {
        uint256 tokenId = _createOriginalTokenId();
        ERC3525Upgradeable._mint(msg.sender, tokenId, slot_, 1);
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
