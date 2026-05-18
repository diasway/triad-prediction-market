// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console2 } from "forge-std/Script.sol";
import { UpgradeableTreasuryV2 } from "../src/UpgradeableTreasuryV2.sol";
import { UpgradeableTreasury } from "../src/UpgradeableTreasury.sol";

contract UpgradeTreasury is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        address proxy = vm.envAddress("TREASURY_PROXY");
        vm.startBroadcast(key);
        UpgradeableTreasuryV2 v2 = new UpgradeableTreasuryV2();
        UpgradeableTreasury(proxy).upgradeToAndCall(address(v2), "");
        vm.stopBroadcast();
        console2.log("Treasury upgraded to V2 implementation", address(v2));
    }
}
