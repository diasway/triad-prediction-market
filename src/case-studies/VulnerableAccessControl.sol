// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VulnerableAccessControl {
    address public treasury;

    function setTreasury(address newTreasury) external {
        treasury = newTreasury;
    }
}
