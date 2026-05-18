// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseSetup } from "./BaseSetup.t.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import { TriadToken } from "../src/TriadToken.sol";
import { ChainlinkPriceOracle } from "../src/ChainlinkPriceOracle.sol";
import { MarketFactory } from "../src/MarketFactory.sol";
import { PredictionMarket } from "../src/PredictionMarket.sol";

contract FinalCoverageBoostTest is BaseSetup {
    function test_oracleConstructorRejectsZeroFeed() public {
        vm.expectRevert(bytes("FEED_ZERO"));
        new ChainlinkPriceOracle(address(0), 1 hours);
    }

    function test_oracleConstructorRejectsZeroMaxAge() public {
        vm.expectRevert(bytes("MAX_AGE_ZERO"));
        new ChainlinkPriceOracle(address(feed), 0);
    }

    function test_factoryConstructorRejectsZeroAdmin() public {
        vm.expectRevert(bytes("ZERO"));
        new MarketFactory(address(0), address(usdc), address(oracle));
    }

    function test_factoryConstructorRejectsZeroCollateral() public {
        vm.expectRevert(bytes("ZERO"));
        new MarketFactory(address(this), address(0), address(oracle));
    }

    function test_factoryConstructorRejectsZeroOracle() public {
        vm.expectRevert(bytes("ZERO"));
        new MarketFactory(address(this), address(usdc), address(0));
    }

    function test_predictionMarketConstructorRejectsZeroAdmin() public {
        vm.expectRevert(bytes("ZERO"));
        new PredictionMarket(
            address(0), address(usdc), address(outcome), address(oracle), 100, 101, 3000e8, 1 days
        );
    }

    function test_predictionMarketConstructorRejectsZeroCollateral() public {
        vm.expectRevert(bytes("ZERO"));
        new PredictionMarket(
            address(this), address(0), address(outcome), address(oracle), 100, 101, 3000e8, 1 days
        );
    }

    function test_predictionMarketConstructorRejectsZeroOutcomeToken() public {
        vm.expectRevert(bytes("ZERO"));
        new PredictionMarket(
            address(this), address(usdc), address(0), address(oracle), 100, 101, 3000e8, 1 days
        );
    }

    function test_ammERC1155ReceiverSelectors() public {
        bytes4 singleSelector = amm.onERC1155Received(address(this), alice, yesId, 1, "");

        assertEq(singleSelector, IERC1155Receiver.onERC1155Received.selector);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = yesId;
        ids[1] = noId;

        amounts[0] = 1;
        amounts[1] = 1;

        bytes4 batchSelector = amm.onERC1155BatchReceived(address(this), alice, ids, amounts, "");

        assertEq(batchSelector, IERC1155Receiver.onERC1155BatchReceived.selector);
        assertTrue(amm.supportsInterface(type(IERC1155Receiver).interfaceId));
    }

    function test_ammGetAmountOutRejectsZeroAmount() public {
        vm.expectRevert(bytes("BAD_RESERVES"));
        amm.getAmountOut(0, 100, 100);
    }

    function test_ammGetAmountOutRejectsZeroReserveIn() public {
        vm.expectRevert(bytes("BAD_RESERVES"));
        amm.getAmountOut(100, 0, 100);
    }

    function test_ammGetAmountOutRejectsZeroReserveOut() public {
        vm.expectRevert(bytes("BAD_RESERVES"));
        amm.getAmountOut(100, 100, 0);
    }

    function test_ammAddLiquiditySlippageReverts() public {
        _buy(alice, 100e6);

        vm.prank(alice);
        vm.expectRevert(bytes("SLIPPAGE"));
        amm.addLiquidity(10e6, 10e6, type(uint256).max);
    }

    function test_ammRemoveLiquiditySlippageReverts() public {
        _buy(alice, 1000e6);

        vm.prank(alice);
        amm.addLiquidity(500e6, 500e6, 1);

        uint256 lp = amm.lpToken().balanceOf(alice);

        vm.prank(alice);
        vm.expectRevert(bytes("SLIPPAGE"));
        amm.removeLiquidity(lp / 2, type(uint256).max, 1);
    }

    function test_ammSwapYesForNoSlippageReverts() public {
        _buy(alice, 1000e6);

        vm.prank(alice);
        amm.addLiquidity(500e6, 500e6, 1);

        _buy(bob, 100e6);

        vm.prank(bob);
        vm.expectRevert(bytes("SLIPPAGE"));
        amm.swapYesForNo(10e6, type(uint256).max);
    }

    function test_ammSwapNoForYesSlippageReverts() public {
        _buy(alice, 1000e6);

        vm.prank(alice);
        amm.addLiquidity(500e6, 500e6, 1);

        _buy(bob, 100e6);

        vm.prank(bob);
        vm.expectRevert(bytes("SLIPPAGE"));
        amm.swapNoForYes(10e6, type(uint256).max);
    }

    function test_ammCollectFeesOnlyRole() public {
        vm.prank(bob);
        vm.expectRevert();
        amm.collectFees(bob);
    }

    function test_marketRedeemBeforeResolvedReverts() public {
        _buy(alice, 100e6);

        vm.prank(alice);
        vm.expectRevert(bytes("NOT_RESOLVED"));
        market.redeem(10e6);
    }

    function test_marketCannotResolveTwice() public {
        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(3200e8);

        market.resolve();

        vm.expectRevert(bytes("BAD_STATE"));
        market.resolve();
    }

    function test_marketBuyAfterResolvedReverts() public {
        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(3200e8);

        market.resolve();

        vm.startPrank(alice);
        usdc.approve(address(market), 100e6);

        vm.expectRevert(bytes("NOT_TRADING"));
        market.buyCompleteSet(100e6);

        vm.stopPrank();
    }

    function test_marketMergeAfterResolvedReverts() public {
        _buy(alice, 100e6);

        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(3200e8);

        market.resolve();

        vm.prank(alice);
        vm.expectRevert(bytes("NOT_TRADING"));
        market.mergeCompleteSet(10e6);
    }

    function test_vaultWithdrawRealFlow() public {
        vm.startPrank(alice);

        usdc.approve(address(vault), 100e6);

        uint256 shares = vault.deposit(100e6, alice);

        uint256 beforeBal = usdc.balanceOf(alice);

        vault.withdraw(40e6, alice, alice);

        assertEq(usdc.balanceOf(alice), beforeBal + 40e6);
        assertLt(vault.balanceOf(alice), shares);

        vm.stopPrank();
    }

    function test_vaultWithdrawWhenPausedReverts() public {
        vm.startPrank(alice);

        usdc.approve(address(vault), 100e6);
        vault.deposit(100e6, alice);

        vm.stopPrank();

        vault.pause();

        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(10e6, alice, alice);
    }

    function test_tokenConstructorLengthMismatch() public {
        address[] memory receivers = new address[](2);
        uint256[] memory amounts = new uint256[](1);

        receivers[0] = alice;
        receivers[1] = bob;
        amounts[0] = 100 ether;

        vm.expectRevert(bytes("LEN"));
        new TriadToken(address(this), receivers, amounts);
    }

    function test_tokenMintByNonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        triad.mint(carol, 1 ether);
    }

    function test_factoryPredictMarketAddressChangesWithSalt() public view {
        address first = factory.predictMarketAddress(bytes32("SALT_A"), 3000e8, 1 days);
        address second = factory.predictMarketAddress(bytes32("SALT_B"), 3000e8, 1 days);

        assertTrue(first != address(0));
        assertTrue(second != address(0));
        assertTrue(first != second);
    }
}
