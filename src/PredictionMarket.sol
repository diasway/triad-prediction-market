// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OutcomeToken} from "./OutcomeToken.sol";
import {ChainlinkPriceOracle} from "./ChainlinkPriceOracle.sol";

contract PredictionMarket is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum State { Trading, Resolved, Cancelled }

    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IERC20 public immutable collateral;
    OutcomeToken public immutable outcomeToken;
    ChainlinkPriceOracle public immutable oracle;
    uint256 public immutable yesId;
    uint256 public immutable noId;
    uint256 public immutable threshold;
    uint256 public immutable disputeWindowEnd;

    State public state;
    bool public winningYes;
    uint256 public totalCollateralLocked;

    event CompleteSetBought(address indexed user, uint256 amount);
    event CompleteSetMerged(address indexed user, uint256 amount);
    event Resolved(bool winningYes, uint256 oraclePrice);
    event Redeemed(address indexed user, uint256 amount, bool yesSide);
    event Cancelled();

    constructor(
        address admin,
        address collateral_,
        address outcomeToken_,
        address oracle_,
        uint256 yesId_,
        uint256 noId_,
        uint256 threshold_,
        uint256 disputeWindowSeconds
    ) {
        require(admin != address(0) && collateral_ != address(0) && outcomeToken_ != address(0), "ZERO");
        collateral = IERC20(collateral_);
        outcomeToken = OutcomeToken(outcomeToken_);
        oracle = ChainlinkPriceOracle(oracle_);
        yesId = yesId_;
        noId = noId_;
        threshold = threshold_;
        disputeWindowEnd = block.timestamp + disputeWindowSeconds;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RESOLVER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        state = State.Trading;
    }

    function buyCompleteSet(uint256 amount) external nonReentrant {
        require(state == State.Trading, "NOT_TRADING");
        require(amount > 0, "ZERO_AMOUNT");
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = yesId; ids[1] = noId;
        amounts[0] = amount; amounts[1] = amount;
        outcomeToken.mintBatch(msg.sender, ids, amounts, "");
        totalCollateralLocked += amount;
        emit CompleteSetBought(msg.sender, amount);
    }

    function mergeCompleteSet(uint256 amount) external nonReentrant {
        require(state == State.Trading, "NOT_TRADING");
        require(amount > 0, "ZERO_AMOUNT");
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = yesId; ids[1] = noId;
        amounts[0] = amount; amounts[1] = amount;
        outcomeToken.burnBatch(msg.sender, ids, amounts);
        totalCollateralLocked -= amount;
        collateral.safeTransfer(msg.sender, amount);
        emit CompleteSetMerged(msg.sender, amount);
    }

    function resolve() external onlyRole(RESOLVER_ROLE) {
        require(state == State.Trading, "BAD_STATE");
        require(block.timestamp >= disputeWindowEnd, "DISPUTE_WINDOW");
        (uint256 price,) = oracle.latestPrice();
        winningYes = price >= threshold;
        state = State.Resolved;
        emit Resolved(winningYes, price);
    }

    function cancel() external onlyRole(PAUSER_ROLE) {
        require(state == State.Trading, "BAD_STATE");
        state = State.Cancelled;
        emit Cancelled();
    }

    function redeem(uint256 amount) external nonReentrant {
        require(state == State.Resolved, "NOT_RESOLVED");
        uint256 id = winningYes ? yesId : noId;
        outcomeToken.burn(msg.sender, id, amount);
        totalCollateralLocked -= amount;
        collateral.safeTransfer(msg.sender, amount);
        emit Redeemed(msg.sender, amount, winningYes);
    }
}
