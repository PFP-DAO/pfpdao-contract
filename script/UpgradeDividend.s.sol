// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {Dividend} from "../src/Dividend.sol";

contract UpgradeDividend is Script {
    function run() public {
        address dividend = vm.envAddress("DIVIDEND_ADDRESS");
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);

        vm.startBroadcast(deployer);

        Dividend wrappedDividend = Dividend(dividend);

        Dividend implementationV2 = new Dividend();

        wrappedDividend.upgradeTo(address(implementationV2));

        // should set all level 20+ roles dividend manually
        // address user1 = 0xe4C6bFd0DDf3D82a2105F1b93578671c58Eb3871;
        // wrappedDividend.setCaptainRight(user1, 1, 39);
        // assert(wrappedDividend.addressCaptainRight(user1, 1) == 39);

        vm.stopBroadcast();
    }
}
