// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { TriadToken } from "../src/TriadToken.sol";
import { TriadGovernor } from "../src/TriadGovernor.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockV3Aggregator } from "../src/mocks/MockV3Aggregator.sol";
import { ChainlinkPriceOracle } from "../src/ChainlinkPriceOracle.sol";
import { MarketFactory } from "../src/MarketFactory.sol";
import { PredictionMarket } from "../src/PredictionMarket.sol";
import { OutcomeAMM } from "../src/OutcomeAMM.sol";
import { OutcomeToken } from "../src/OutcomeToken.sol";
import { ProtocolFeeVault } from "../src/ProtocolFeeVault.sol";

abstract contract BaseSetup is Test {
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal carol = address(0xCA801);
    address internal admin = address(this);

    MockERC20 internal usdc;
    MockV3Aggregator internal feed;
    ChainlinkPriceOracle internal oracle;
    TriadToken internal triad;
    TimelockController internal timelock;
    TriadGovernor internal governor;
    MarketFactory internal factory;
    OutcomeToken internal outcome;
    PredictionMarket internal market;
    OutcomeAMM internal amm;
    ProtocolFeeVault internal vault;
    uint256 internal yesId;
    uint256 internal noId;

    function setUp() public virtual {
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        feed = new MockV3Aggregator(8, 3000e8);
        oracle = new ChainlinkPriceOracle(address(feed), 1 hours);

        address[] memory receivers = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        receivers[0] = admin;
        amounts[0] = 8_000_000 ether;
        receivers[1] = alice;
        amounts[1] = 1_000_000 ether;
        receivers[2] = bob;
        amounts[2] = 1_000_000 ether;
        triad = new TriadToken(admin, receivers, amounts);
        triad.delegate(admin);
        vm.prank(alice);
        triad.delegate(alice);
        vm.prank(bob);
        triad.delegate(bob);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        timelock = new TimelockController(2 days, proposers, executors, admin);
        governor = new TriadGovernor(triad, timelock);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), admin);

        factory = new MarketFactory(admin, address(usdc), address(oracle));
        (uint256 marketId, address m, address a) =
            factory.createMarket(bytes32("ETH3000"), 3000e8, 1 days);
        market = PredictionMarket(m);
        amm = OutcomeAMM(a);
        outcome = factory.outcomeToken();
        yesId = marketId * 2;
        noId = marketId * 2 + 1;

        usdc.mint(alice, 1_000_000e6);
        usdc.mint(bob, 1_000_000e6);
        usdc.mint(carol, 1_000_000e6);
        vault = new ProtocolFeeVault(usdc, admin);
    }

    function _buy(address user, uint256 amount) internal {
        vm.startPrank(user);
        usdc.approve(address(market), amount);
        market.buyCompleteSet(amount);
        outcome.setApprovalForAll(address(amm), true);
        vm.stopPrank();
    }
}
