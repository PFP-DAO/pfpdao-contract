// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Errors {
    error InvalidSignature();
    error WhiteListUsed(uint8);
    error InvaildLootTimes();
    error USDCPaymentFailed();
    error NotEnoughMATIC();
    error NotAllowed();
    error Soulbound();
    error NotApprove();
    error NotBurner(address);
    error InvalidSlot();
    error NotReachLimit(uint8);
    error NotOwner();
    error InvalidLength();
}
