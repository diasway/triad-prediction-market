// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FixedPullPayout is ReentrancyGuard {
    mapping(address => uint256) public credit;

    function deposit() external payable { credit[msg.sender] += msg.value; }

    function withdraw() external nonReentrant {
        uint256 amount = credit[msg.sender];
        require(amount > 0, "NO_CREDIT");
        credit[msg.sender] = 0;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "CALL_FAILED");
    }
}
