// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseSetup } from "./BaseSetup.t.sol";

contract DummyTarget {
    uint256 public value;

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}

contract GovernorCoverageTest is BaseSetup {
    function test_governorFullProposalVoteQueueExecuteLifecycle() public {
        DummyTarget target = new DummyTarget();

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(target);
        values[0] = 0;
        calldatas[0] = abi.encodeCall(DummyTarget.setValue, (123));

        string memory description = "Set dummy value to 123";
        bytes32 descriptionHash = keccak256(bytes(description));

        vm.roll(block.number + 2);

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertEq(uint256(governor.state(proposalId)), 0);

        vm.roll(governor.proposalSnapshot(proposalId) + 1);

        assertEq(uint256(governor.state(proposalId)), 1);

        governor.castVote(proposalId, 1);

        vm.roll(governor.proposalDeadline(proposalId) + 1);

        assertEq(uint256(governor.state(proposalId)), 4);
        assertTrue(governor.proposalNeedsQueuing(proposalId));

        governor.queue(targets, values, calldatas, descriptionHash);

        assertEq(uint256(governor.state(proposalId)), 5);

        vm.warp(block.timestamp + timelock.getMinDelay() + 1);

        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(target.value(), 123);
        assertEq(uint256(governor.state(proposalId)), 7);
    }

    function test_governorDefeatedProposalState() public {
        DummyTarget target = new DummyTarget();

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(target);
        values[0] = 0;
        calldatas[0] = abi.encodeCall(DummyTarget.setValue, (777));

        string memory description = "Defeated proposal";

        vm.roll(block.number + 2);

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(governor.proposalSnapshot(proposalId) + 1);

        vm.prank(bob);
        governor.castVote(proposalId, 0);

        vm.roll(governor.proposalDeadline(proposalId) + 1);

        assertEq(uint256(governor.state(proposalId)), 3);
    }
}
