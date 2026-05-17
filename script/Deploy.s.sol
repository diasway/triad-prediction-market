// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TriadToken} from "../src/TriadToken.sol";
import {TriadGovernor} from "../src/TriadGovernor.sol";
import {ChainlinkPriceOracle} from "../src/ChainlinkPriceOracle.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {ProtocolFeeVault} from "../src/ProtocolFeeVault.sol";
import {UpgradeableTreasury} from "../src/UpgradeableTreasury.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";

contract Deploy is Script {
    uint256 internal constant MIN_DELAY = 2 days;
    uint256 internal constant MAX_PRICE_AGE = 1 hours;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);

        MockERC20 collateral = new MockERC20("Mock USDC", "mUSDC", 6);
        MockV3Aggregator feed = new MockV3Aggregator(8, 3000e8);
        ChainlinkPriceOracle oracle = new ChainlinkPriceOracle(address(feed), MAX_PRICE_AGE);

        address[] memory receivers = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        receivers[0] = deployer;
        amounts[0] = 10_000_000 ether;
        TriadToken token = new TriadToken(deployer, receivers, amounts);
        token.delegate(deployer);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        TimelockController timelock = new TimelockController(MIN_DELAY, proposers, executors, deployer);
        TriadGovernor governor = new TriadGovernor(token, timelock);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);

        MarketFactory factory = new MarketFactory(address(timelock), address(collateral), address(oracle));
        ProtocolFeeVault vault = new ProtocolFeeVault(collateral, address(timelock));

        UpgradeableTreasury impl = new UpgradeableTreasury();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeCall(UpgradeableTreasury.initialize, (address(timelock))));

        vm.stopBroadcast();

        console2.log("TRIAD", address(token));
        console2.log("TIMELOCK", address(timelock));
        console2.log("GOVERNOR", address(governor));
        console2.log("COLLATERAL", address(collateral));
        console2.log("ORACLE", address(oracle));
        console2.log("FACTORY", address(factory));
        console2.log("FEE_VAULT", address(vault));
        console2.log("TREASURY_PROXY", address(proxy));
    }
}
