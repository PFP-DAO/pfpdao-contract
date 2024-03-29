// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDividend {
    function claim(address user_, uint16 captainId_) external;
    function transferCaptainRight(address from_, address to_, uint16 captainId_, uint256 right_) external;
    function addCaptainRight(address user_, uint16 captainId_, uint256 addRight_) external;
    function batch() external view returns (uint256);
    function setNewBatch() external;
    function updateRoleIdPoolBalance(uint256 batch_, uint16 captainId_, uint256 newBalance_) external;
}
