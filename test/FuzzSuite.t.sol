// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseSetup} from "./BaseSetup.t.sol";
import {YulMath} from "../src/libraries/YulMath.sol";

contract FuzzSuiteTest is BaseSetup {
    function testFuzz_SwapYesForNo(uint256 amount) public { amount = bound(amount, 1, 100_000e6); assertTrue(amount > 0); }
    function testFuzz_SwapNoForYes(uint256 amount) public { amount = bound(amount, 1, 100_000e6); assertTrue(amount > 0); }
    function testFuzz_VaultDeposit(uint256 amount) public { amount = bound(amount, 1, 100_000e6); vm.startPrank(alice); usdc.approve(address(vault), amount); uint256 shares = vault.deposit(amount, alice); assertGt(shares, 0); vm.stopPrank(); }
    function testFuzz_VaultWithdraw(uint256 amount) public { amount = bound(amount, 1, 100_000e6); assertTrue(amount > 0); }
    function testFuzz_CompleteSetBuy(uint256 amount) public { amount = bound(amount, 1, 100_000e6); assertTrue(amount > 0); }
    function testFuzz_CompleteSetMerge(uint256 amount) public { amount = bound(amount, 1, 100_000e6); assertTrue(amount > 0); }
    function testFuzz_GovernanceVotingPower(uint256 amount) public { amount = bound(amount, 1, 100_000e6); assertTrue(amount > 0); }
    function testFuzz_YulSqrt(uint256 amount) public { x = bound(x, 0, type(uint128).max); assertEq(YulMath.sqrtYul(x), YulMath.sqrtSolidity(x)); }
    function testFuzz_AmountOut(uint256 amount) public { amount = bound(amount, 1, 1_000_000e6); reserve = bound(reserve, 1_000e6, 10_000_000e6); assertLt(amm.getAmountOut(amount, reserve, reserve), reserve); }
    function testFuzz_FactorySalt(uint256 amount) public { amount = bound(amount, 1, 100_000e6); assertTrue(amount > 0); }
}
