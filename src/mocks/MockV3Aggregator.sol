// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AggregatorV3Interface } from "../interfaces/AggregatorV3Interface.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    uint8 public immutable override decimals;
    string public override description;
    uint256 public override version = 1;

    uint80 public roundId = 1;
    int256 public answer;
    uint256 public updatedAt;

    constructor(uint8 decimals_, int256 initialAnswer) {
        decimals = decimals_;
        description = "Mock Chainlink Feed";
        answer = initialAnswer;
        updatedAt = block.timestamp;
    }

    function updateAnswer(int256 newAnswer) external {
        roundId += 1;
        answer = newAnswer;
        updatedAt = block.timestamp;
    }

    function setUpdatedAt(uint256 ts) external {
        updatedAt = ts;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, answer, updatedAt, updatedAt, roundId);
    }
}
