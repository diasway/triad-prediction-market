// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { UpgradeableTreasury } from "../src/UpgradeableTreasury.sol";
import { UpgradeableTreasuryV2 } from "../src/UpgradeableTreasuryV2.sol";

import { VulnerableAccessControl } from "../src/case-studies/VulnerableAccessControl.sol";
import { FixedAccessControl } from "../src/case-studies/FixedAccessControl.sol";
import { VulnerablePushPayout } from "../src/case-studies/VulnerablePushPayout.sol";
import { FixedPullPayout } from "../src/case-studies/FixedPullPayout.sol";

contract CoverageBoostTest is Test {
    address user = address(0xBEEF);
    address other = address(0xCAFE);

    MockERC20 token;

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        token.mint(address(this), 1000 ether);
        token.mint(user, 1000 ether);
    }

    function test_treasuryV1DepositWithdrawAndVersion() public {
        UpgradeableTreasury impl = new UpgradeableTreasury();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeCall(UpgradeableTreasury.initialize, (address(this)))
        );

        UpgradeableTreasury treasury = UpgradeableTreasury(address(proxy));

        assertEq(treasury.version(), "v1");

        token.approve(address(treasury), 100 ether);
        treasury.deposit(address(token), 100 ether);

        assertEq(treasury.accountedBalance(address(token)), 100 ether);

        treasury.withdraw(address(token), other, 40 ether);

        assertEq(treasury.accountedBalance(address(token)), 60 ether);
        assertEq(token.balanceOf(other), 40 ether);
    }

    function test_treasuryRejectsZeroDeposit() public {
        UpgradeableTreasury impl = new UpgradeableTreasury();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeCall(UpgradeableTreasury.initialize, (address(this)))
        );

        UpgradeableTreasury treasury = UpgradeableTreasury(address(proxy));

        vm.expectRevert();
        treasury.deposit(address(token), 0);
    }

    function test_treasuryRejectsUnauthorizedWithdraw() public {
        UpgradeableTreasury impl = new UpgradeableTreasury();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeCall(UpgradeableTreasury.initialize, (address(this)))
        );

        UpgradeableTreasury treasury = UpgradeableTreasury(address(proxy));

        token.approve(address(treasury), 100 ether);
        treasury.deposit(address(token), 100 ether);

        vm.prank(user);
        vm.expectRevert();
        treasury.withdraw(address(token), user, 10 ether);
    }

    function test_treasuryV2UpgradeAndCorrection() public {
        UpgradeableTreasury impl = new UpgradeableTreasury();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeCall(UpgradeableTreasury.initialize, (address(this)))
        );

        UpgradeableTreasury treasury = UpgradeableTreasury(address(proxy));

        token.approve(address(treasury), 100 ether);
        treasury.deposit(address(token), 100 ether);

        UpgradeableTreasuryV2 v2 = new UpgradeableTreasuryV2();

        treasury.upgradeToAndCall(address(v2), "");

        UpgradeableTreasuryV2 upgraded = UpgradeableTreasuryV2(address(proxy));

        assertEq(upgraded.version(), "v2");
        assertEq(upgraded.accountedBalance(address(token)), 100 ether);

        upgraded.correctAccounting(address(token), 55 ether);

        assertEq(upgraded.accountedBalance(address(token)), 55 ether);
    }

    function test_vulnerableAccessControlCanBeChangedByAnyone() public {
        VulnerableAccessControl vulnerable = new VulnerableAccessControl();

        vm.prank(user);
        vulnerable.setTreasury(other);

        assertEq(vulnerable.treasury(), other);
    }

    function test_fixedAccessControlOnlyOwnerCanChange() public {
        FixedAccessControl fixedContract = new FixedAccessControl(address(this));

        fixedContract.setTreasury(other);
        assertEq(fixedContract.treasury(), other);

        vm.prank(user);
        vm.expectRevert();
        fixedContract.setTreasury(user);
    }

    function test_vulnerablePushPayoutDepositWithdraw() public {
        VulnerablePushPayout payout = new VulnerablePushPayout();

        payout.deposit{ value: 1 ether }();

        assertEq(payout.credit(address(this)), 1 ether);

        payout.withdraw();

        assertEq(payout.credit(address(this)), 0);
    }

    function test_fixedPullPayoutDepositWithdraw() public {
        FixedPullPayout payout = new FixedPullPayout();

        payout.deposit{ value: 1 ether }();

        assertEq(payout.credit(address(this)), 1 ether);

        payout.withdraw();

        assertEq(payout.credit(address(this)), 0);
    }

    receive() external payable { }
}
