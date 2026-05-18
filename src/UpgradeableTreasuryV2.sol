// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { UpgradeableTreasury } from "./UpgradeableTreasury.sol";

contract UpgradeableTreasuryV2 is UpgradeableTreasury {
    event EmergencyAccountingCorrection(address indexed token, uint256 oldValue, uint256 newValue);

    function correctAccounting(address token, uint256 newValue) external onlyRole(TREASURER_ROLE) {
        uint256 oldValue = _accountedBalance[token];
        _accountedBalance[token] = newValue;
        emit EmergencyAccountingCorrection(token, oldValue, newValue);
    }

    function version() external pure override returns (string memory) {
        return "v2";
    }
}
