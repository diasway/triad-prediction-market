// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AggregatorV3Interface } from "./interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceOracle {
    error StalePrice(uint256 updatedAt, uint256 maxAge);
    error InvalidPrice(int256 price);
    error IncompleteRound(uint80 answeredInRound, uint80 roundId);
    error RoundNotStarted(uint256 startedAt);

    AggregatorV3Interface public immutable feed;
    uint256 public immutable maxAge;

    constructor(address feed_, uint256 maxAge_) {
        require(feed_ != address(0), "FEED_ZERO");
        require(maxAge_ > 0, "MAX_AGE_ZERO");

        feed = AggregatorV3Interface(feed_);
        maxAge = maxAge_;
    }

    function latestPrice() public view returns (uint256 price, uint8 decimals) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = feed.latestRoundData();

        if (startedAt == 0) revert RoundNotStarted(startedAt);
        if (answer <= 0) revert InvalidPrice(answer);
        if (answeredInRound < roundId) revert IncompleteRound(answeredInRound, roundId);
        if (block.timestamp - updatedAt > maxAge) revert StalePrice(updatedAt, maxAge);

        return (uint256(answer), feed.decimals());
    }
}
