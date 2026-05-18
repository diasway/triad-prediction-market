// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseSetup } from "./BaseSetup.t.sol";
import { TriadToken } from "../src/TriadToken.sol";

contract MoreCoverageTest is BaseSetup {
    function test_outcomeTokenDirectMintAndBurn() public {
        outcome.grantRole(outcome.MINTER_ROLE(), address(this));
        outcome.grantRole(outcome.BURNER_ROLE(), address(this));

        outcome.mint(alice, 999, 100, "");

        assertEq(outcome.balanceOf(alice, 999), 100);

        outcome.burn(alice, 999, 40);

        assertEq(outcome.balanceOf(alice, 999), 60);
    }

    function test_outcomeTokenBatchMintAndBurn() public {
        outcome.grantRole(outcome.MINTER_ROLE(), address(this));
        outcome.grantRole(outcome.BURNER_ROLE(), address(this));

        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 111;
        ids[1] = 222;

        amounts[0] = 10;
        amounts[1] = 20;

        outcome.mintBatch(alice, ids, amounts, "");

        assertEq(outcome.balanceOf(alice, 111), 10);
        assertEq(outcome.balanceOf(alice, 222), 20);

        outcome.burnBatch(alice, ids, amounts);

        assertEq(outcome.balanceOf(alice, 111), 0);
        assertEq(outcome.balanceOf(alice, 222), 0);
    }

    function test_marketResolveYesAndRedeemRealFlow() public {
        _buy(alice, 100e6);

        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(3200e8);

        market.resolve();

        assertEq(uint256(market.state()), 1);
        assertTrue(market.winningYes());

        uint256 beforeBal = usdc.balanceOf(alice);

        vm.prank(alice);
        market.redeem(50e6);

        assertEq(usdc.balanceOf(alice), beforeBal + 50e6);
        assertEq(outcome.balanceOf(alice, yesId), 50e6);
    }

    function test_marketResolveNoAndRedeemRealFlow() public {
        _buy(alice, 100e6);

        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(2500e8);

        market.resolve();

        assertEq(uint256(market.state()), 1);
        assertFalse(market.winningYes());

        uint256 beforeBal = usdc.balanceOf(alice);

        vm.prank(alice);
        market.redeem(40e6);

        assertEq(usdc.balanceOf(alice), beforeBal + 40e6);
        assertEq(outcome.balanceOf(alice, noId), 60e6);
    }

    function test_marketMergeCompleteSetRealFlow() public {
        _buy(alice, 100e6);

        uint256 beforeBal = usdc.balanceOf(alice);

        vm.prank(alice);
        market.mergeCompleteSet(30e6);

        assertEq(usdc.balanceOf(alice), beforeBal + 30e6);
        assertEq(outcome.balanceOf(alice, yesId), 70e6);
        assertEq(outcome.balanceOf(alice, noId), 70e6);
    }

    function test_marketCancelBlocksResolveAndRedeem() public {
        _buy(alice, 100e6);

        market.cancel();

        assertEq(uint256(market.state()), 2);

        vm.warp(block.timestamp + 2 days);
        feed.updateAnswer(3200e8);

        vm.expectRevert();
        market.resolve();

        vm.prank(alice);
        vm.expectRevert();
        market.redeem(10e6);
    }

    function test_ammRemoveLiquidityRealFlow() public {
        _buy(alice, 1000e6);

        vm.prank(alice);
        amm.addLiquidity(500e6, 500e6, 1);

        uint256 lp = amm.lpToken().balanceOf(alice);

        assertGt(lp, 0);

        vm.prank(alice);
        amm.removeLiquidity(lp / 2, 1, 1);

        assertGt(outcome.balanceOf(alice, yesId), 0);
        assertGt(outcome.balanceOf(alice, noId), 0);
    }

    function test_ammSwapNoForYesRealFlow() public {
        _buy(alice, 1000e6);

        vm.prank(alice);
        amm.addLiquidity(500e6, 500e6, 1);

        _buy(bob, 100e6);

        uint256 beforeYes = outcome.balanceOf(bob, yesId);

        vm.prank(bob);
        uint256 out = amm.swapNoForYes(10e6, 1);

        assertGt(out, 0);
        assertGt(outcome.balanceOf(bob, yesId), beforeYes);
    }

    function test_ammCollectFeesAfterSwap() public {
        _buy(alice, 1000e6);

        vm.prank(alice);
        amm.addLiquidity(500e6, 500e6, 1);

        _buy(bob, 100e6);

        vm.prank(bob);
        amm.swapYesForNo(10e6, 1);

        uint256 feesBefore = amm.accumulatedFees();

        assertGt(feesBefore, 0);

        uint256 collected = amm.collectFees(address(this));

        assertEq(collected, feesBefore);
        assertEq(amm.accumulatedFees(), 0);
    }

    function test_factoryCreateSecondMarket() public {
        uint256 beforeId = factory.nextMarketId();

        (uint256 marketId, address marketAddr, address ammAddr) =
            factory.createMarket(bytes32("BTC70000"), 70000e8, 1 days);

        assertEq(marketId, beforeId);
        assertTrue(marketAddr != address(0));
        assertTrue(ammAddr != address(0));

        (address storedMarket, address storedAmm, uint256 storedYes, uint256 storedNo,) =
            factory.markets(marketId);

        assertEq(storedMarket, marketAddr);
        assertEq(storedAmm, ammAddr);
        assertEq(storedYes, marketId * 2);
        assertEq(storedNo, marketId * 2 + 1);
    }

    function test_vaultPauseUnpauseDepositFlow() public {
        vault.pause();

        vm.startPrank(alice);
        usdc.approve(address(vault), 100e6);

        vm.expectRevert();
        vault.deposit(100e6, alice);

        vm.stopPrank();

        vault.unpause();

        vm.startPrank(alice);
        uint256 shares = vault.deposit(100e6, alice);
        vm.stopPrank();

        assertGt(shares, 0);
        assertEq(vault.balanceOf(alice), shares);
    }

    function test_tokenOwnerMintIncreasesBalance() public {
        address[] memory receivers = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        receivers[0] = address(this);
        amounts[0] = 100 ether;

        TriadToken token = new TriadToken(address(this), receivers, amounts);

        uint256 beforeBal = token.balanceOf(carol);

        token.mint(carol, 100 ether);

        assertEq(token.balanceOf(carol), beforeBal + 100 ether);
    }
}
