// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VulnerablePushPayout {
    mapping(address => uint256) public credit;

    function deposit() external payable {
        credit[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = credit[msg.sender];
        require(amount > 0, "NO_CREDIT");
        (bool ok,) = msg.sender.call{ value: amount }("");
        require(ok, "CALL_FAILED");
        credit[msg.sender] = 0;
    }
}
