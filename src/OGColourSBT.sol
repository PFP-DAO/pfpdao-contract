// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

error Minted(address);

error Soulbound();

contract OGColourSBT is
    ContextUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ERC1155URIStorageUpgradeable
{
    mapping(address => uint8) public userColour;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        _setBaseURI("https://pfpdao-test-0.4everland.store/ogSBT/metadata/");
        _setURI(1, "1");
        _setURI(2, "2");
        _setURI(3, "3");
        _setURI(4, "4");
        _setURI(5, "5");
    }

    function mint() external {
        _requireNotPaused();
        if (userColour[_msgSender()] != 0) {
            revert Minted(_msgSender());
        } else {
            uint256 seed = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp)));
            uint8 colour = uint8(seed % 5);
            _mint(_msgSender(), colour + 1, 1, "");
            userColour[_msgSender()] = colour + 1;
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != address(0) && to != address(0)) {
            revert Soulbound();
        }
    }

    function setPause(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

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
