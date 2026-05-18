// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseSetup } from "./BaseSetup.t.sol";

import { OutcomeAMM } from "../src/OutcomeAMM.sol";
import { ChainlinkPriceOracle } from "../src/ChainlinkPriceOracle.sol";
import { AggregatorV3Interface } from "../src/interfaces/AggregatorV3Interface.sol";
import { YulMath } from "../src/libraries/YulMath.sol";
import { LPToken } from "../src/LPToken.sol";

contract FakeIncompleteFeed is AggregatorV3Interface {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function description() external pure returns (string memory) {
        return "Fake incomplete feed";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (2, 3000e8, block.timestamp, block.timestamp, 1);
    }
}

contract LastCoveragePushTest is BaseSetup {
    function test_oracleRejectsIncompleteRound() public {
        FakeIncompleteFeed badFeed = new FakeIncompleteFeed();
        ChainlinkPriceOracle badOracle = new ChainlinkPriceOracle(address(badFeed), 1 hours);

        vm.expectRevert();
        badOracle.latestPrice();
    }

    function test_yulMathMinBothBranches() public pure {
        assertEq(YulMath.min(1, 2), 1);
        assertEq(YulMath.min(5, 3), 3);
    }

    function test_ammConstructorRejectsZeroAdmin() public {
        vm.expectRevert(bytes("ZERO"));
        new OutcomeAMM(address(0), address(usdc), address(outcome), yesId, noId);
    }

    function test_ammConstructorRejectsZeroCollateral() public {
        vm.expectRevert(bytes("ZERO"));
        new OutcomeAMM(address(this), address(0), address(outcome), yesId, noId);
    }

    function test_ammConstructorRejectsZeroOutcomeToken() public {
        vm.expectRevert(bytes("ZERO"));
        new OutcomeAMM(address(this), address(usdc), address(0), yesId, noId);
    }

    function test_ammAddLiquiditySecondProviderUsesExistingSupplyBranch() public {
        _buy(alice, 1000e6);

        vm.prank(alice);
        amm.addLiquidity(500e6, 500e6, 1);

        _buy(bob, 1000e6);

        vm.prank(bob);
        amm.addLiquidity(200e6, 200e6, 1);

        assertGt(amm.lpToken().balanceOf(bob), 0);
    }

    function test_ammRemoveLiquidityWithoutLiquidityReverts() public {
        OutcomeAMM emptyAmm =
            new OutcomeAMM(address(this), address(usdc), address(outcome), 777, 778);

        vm.expectRevert(bytes("NO_LIQUIDITY"));
        emptyAmm.removeLiquidity(1, 1, 1);
    }

    function test_lpTokenDirectMintOnlyOwnerReverts() public {
        LPToken lp = amm.lpToken();

        vm.prank(alice);
        vm.expectRevert();
        lp.mint(alice, 1);
    }

    function test_marketResolveOnlyResolverRole() public {
        vm.warp(block.timestamp + 2 days);

        vm.prank(bob);
        vm.expectRevert();
        market.resolve();
    }

    function test_marketCancelOnlyPauserRole() public {
        vm.prank(bob);
        vm.expectRevert();
        market.cancel();
    }

    function test_marketCancelAfterResolvedReverts() public {
        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(3200e8);

        market.resolve();

        vm.expectRevert(bytes("BAD_STATE"));
        market.cancel();
    }

    function test_marketMergeZeroAmountReverts() public {
        vm.prank(alice);
        vm.expectRevert(bytes("ZERO_AMOUNT"));
        market.mergeCompleteSet(0);
    }

    function test_marketRedeemBurnsWinningNoToken() public {
        _buy(alice, 100e6);

        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(2500e8);

        market.resolve();

        uint256 beforeBal = usdc.balanceOf(alice);

        vm.prank(alice);
        market.redeem(25e6);

        assertEq(usdc.balanceOf(alice), beforeBal + 25e6);
        assertEq(outcome.balanceOf(alice, noId), 75e6);
    }

    function test_vaultPauseOnlyRole() public {
        vm.prank(bob);
        vm.expectRevert();
        vault.pause();
    }

    function test_vaultUnpauseOnlyRole() public {
        vault.pause();

        vm.prank(bob);
        vm.expectRevert();
        vault.unpause();
    }

    function test_outcomeTokenUnauthorizedMintReverts() public {
        vm.prank(bob);
        vm.expectRevert();
        outcome.mint(bob, 999, 1, "");
    }

    function test_outcomeTokenUnauthorizedBurnReverts() public {
        outcome.grantRole(outcome.MINTER_ROLE(), address(this));
        outcome.mint(bob, 999, 10, "");

        vm.prank(bob);
        vm.expectRevert();
        outcome.burn(bob, 999, 1);
    }

    function test_factoryCreateMarketOnlyCreatorRole() public {
        vm.prank(bob);
        vm.expectRevert();
        factory.createMarket(bytes32("NO_ROLE"), 3000e8, 1 days);
    }
}
