// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "erc-3525/ERC3525Upgradeable.sol";
import {Errors} from "./libraries/Errors.sol";

contract PFPDAO is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC3525Upgradeable, UUPSUpgradeable {
    uint32[89] public expTable;
    uint8[] public levelNeedAwakening;

    mapping(address => bool) public activePools;

    address[] public allowedBurners;

    modifier onlyActivePool() {
        require(activePools[_msgSender()], "only active pool can mint");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function __PFPDAO_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC3525_init(name_, symbol_, 0);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __PFPDAO_init_unchained();
    }

    function __PFPDAO_init_unchained() internal onlyInitializing {
        expTable = [
            10, //1 to 2
            11,
            12,
            13,
            15,
            16,
            18,
            19,
            21,
            24,
            26,
            29,
            31,
            35,
            38,
            42,
            46,
            51,
            56, // 19 to 20
            61,
            67,
            74,
            81,
            90,
            98,
            108,
            119,
            131,
            144,
            159,
            174,
            192,
            211,
            232,
            255,
            281,
            309,
            340,
            374, // 39 to 40
            411,
            453,
            498,
            548,
            602,
            663,
            729,
            802,
            882,
            970,
            1067,
            1174,
            1291,
            1420,
            1562,
            1719,
            1891,
            2080,
            2288,
            2516, // 59 to 60
            2768,
            3045,
            3349,
            3684,
            4053,
            4458,
            4904,
            5394,
            5933,
            6527,
            7180,
            7897,
            8687,
            9556,
            10512,
            11563,
            12719,
            13991,
            15390,
            16929, // 79 to 80
            18622,
            20484,
            22532,
            24786,
            27264,
            29991,
            32990,
            36289,
            39918,
            43909 // 89 to 90
        ];
        levelNeedAwakening = [20, 40, 60, 80, 90];
    }

    function isActivePool(address pool_) external view returns (bool) {
        return activePools[pool_];
    }

    function burn(uint256 tokenId_) public {
        if (!_isAllowedBurner(_msgSender())) {
            revert Errors.NotBurner(_msgSender());
        }
        _burn(tokenId_);
    }

    function getAllowedBurner(uint256 index_) public view returns (address) {
        return allowedBurners[index_];
    }

    function _isAllowedBurner(address _address) private view returns (bool) {
        for (uint256 i = 0; i < allowedBurners.length; i++) {
            if (allowedBurners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    /* admin functions */
    function updateAllowedBurners(address[] calldata _allowedBurners) external onlyOwner {
        allowedBurners = _allowedBurners;
    }

    function addActivePool(address pool_) external onlyOwner {
        activePools[pool_] = true;
    }

    function removeActivePool(address pool_) external onlyOwner {
        activePools[pool_] = false;
    }

    /* upgrade functions */
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
