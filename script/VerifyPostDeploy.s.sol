// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {TriadGovernor} from "../src/TriadGovernor.sol";

contract VerifyPostDeploy is Script {
    function run() external view {
        address governorAddr = vm.envAddress("GOVERNOR");
        address timelockAddr = vm.envAddress("TIMELOCK");
        TriadGovernor governor = TriadGovernor(payable(governorAddr));
        TimelockController timelock = TimelockController(payable(timelockAddr));

        require(timelock.getMinDelay() == 2 days, "BAD_TIMELOCK_DELAY");
        require(governor.votingDelay() == 1 days, "BAD_VOTING_DELAY");
        require(governor.votingPeriod() == 1 weeks, "BAD_VOTING_PERIOD");
        require(governor.quorumNumerator() == 4, "BAD_QUORUM");
        require(timelock.hasRole(timelock.PROPOSER_ROLE(), governorAddr), "GOVERNOR_NOT_PROPOSER");
        require(!timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), msg.sender), "ADMIN_BACKDOOR");
        console2.log("Post-deployment verification passed");
    }
}
