// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract TriadToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000_000 ether;

    constructor(address initialOwner, address[] memory receivers, uint256[] memory amounts)
        ERC20("Triad Governance Token", "TRIAD")
        ERC20Permit("Triad Governance Token")
        Ownable(initialOwner)
    {
        require(receivers.length == amounts.length, "LEN");
        for (uint256 i; i < receivers.length; ++i) {
            _mint(receivers[i], amounts[i]);
        }
        require(totalSupply() <= MAX_SUPPLY, "MAX_SUPPLY");
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "MAX_SUPPLY");
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
