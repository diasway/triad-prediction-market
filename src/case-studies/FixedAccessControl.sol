// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FixedAccessControl is Ownable {
    address public treasury;
    constructor(address owner_) Ownable(owner_) {}
    function setTreasury(address newTreasury) external onlyOwner { treasury = newTreasury; }
}
