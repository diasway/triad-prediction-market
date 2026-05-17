// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {YulMath} from "./libraries/YulMath.sol";
import {LPToken} from "./LPToken.sol";

contract OutcomeAMM is IERC1155Receiver, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    uint256 public constant FEE_BPS = 30; // 0.3%
    uint256 public constant BPS = 10_000;

    IERC20 public immutable collateral;
    IERC1155 public immutable outcomeToken;
    LPToken public immutable lpToken;
    uint256 public immutable yesId;
    uint256 public immutable noId;

    uint256 public yesReserve;
    uint256 public noReserve;
    uint256 public accumulatedFees;

    event LiquidityAdded(address indexed provider, uint256 yesAmount, uint256 noAmount, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 yesAmount, uint256 noAmount, uint256 lpBurned);
    event Swap(address indexed trader, uint256 indexed tokenIn, uint256 amountIn, uint256 amountOut);
    event FeesCollected(address indexed collector, uint256 amount);

    constructor(address admin, address collateral_, address outcomeToken_, uint256 yesId_, uint256 noId_) {
        require(admin != address(0) && collateral_ != address(0) && outcomeToken_ != address(0), "ZERO");
        collateral = IERC20(collateral_);
        outcomeToken = IERC1155(outcomeToken_);
        yesId = yesId_;
        noId = noId_;
        lpToken = new LPToken(address(this), "Triad Market LP", "TMLP");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FEE_COLLECTOR_ROLE, admin);
    }

    function addLiquidity(uint256 yesAmount, uint256 noAmount, uint256 minLpOut)
        external
        nonReentrant
        returns (uint256 lpOut)
    {
        require(yesAmount > 0 && noAmount > 0, "ZERO_AMOUNT");
        uint256 supply = lpToken.totalSupply();
        if (supply == 0) {
            lpOut = YulMath.sqrtYul(yesAmount * noAmount);
        } else {
            lpOut = YulMath.min((yesAmount * supply) / yesReserve, (noAmount * supply) / noReserve);
        }
        require(lpOut >= minLpOut && lpOut > 0, "SLIPPAGE");

        outcomeToken.safeTransferFrom(msg.sender, address(this), yesId, yesAmount, "");
        outcomeToken.safeTransferFrom(msg.sender, address(this), noId, noAmount, "");
        yesReserve += yesAmount;
        noReserve += noAmount;
        lpToken.mint(msg.sender, lpOut);
        emit LiquidityAdded(msg.sender, yesAmount, noAmount, lpOut);
    }

    function removeLiquidity(uint256 lpAmount, uint256 minYesOut, uint256 minNoOut)
        external
        nonReentrant
        returns (uint256 yesOut, uint256 noOut)
    {
        uint256 supply = lpToken.totalSupply();
        require(lpAmount > 0 && supply > 0, "NO_LIQUIDITY");
        yesOut = (yesReserve * lpAmount) / supply;
        noOut = (noReserve * lpAmount) / supply;
        require(yesOut >= minYesOut && noOut >= minNoOut, "SLIPPAGE");
        yesReserve -= yesOut;
        noReserve -= noOut;
        lpToken.burn(msg.sender, lpAmount);
        outcomeToken.safeTransferFrom(address(this), msg.sender, yesId, yesOut, "");
        outcomeToken.safeTransferFrom(address(this), msg.sender, noId, noOut, "");
        emit LiquidityRemoved(msg.sender, yesOut, noOut, lpAmount);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256)
    {
        require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "BAD_RESERVES");
        uint256 amountInAfterFee = amountIn * (BPS - FEE_BPS);
        return (amountInAfterFee * reserveOut) / (reserveIn * BPS + amountInAfterFee);
    }

    function swapYesForNo(uint256 amountIn, uint256 minNoOut)
        external
        nonReentrant
        returns (uint256 noOut)
    {
        noOut = getAmountOut(amountIn, yesReserve, noReserve);
        require(noOut >= minNoOut, "SLIPPAGE");
        uint256 fee = (amountIn * FEE_BPS) / BPS;
        outcomeToken.safeTransferFrom(msg.sender, address(this), yesId, amountIn, "");
        yesReserve += amountIn - fee;
        noReserve -= noOut;
        accumulatedFees += fee;
        outcomeToken.safeTransferFrom(address(this), msg.sender, noId, noOut, "");
        emit Swap(msg.sender, yesId, amountIn, noOut);
    }

    function swapNoForYes(uint256 amountIn, uint256 minYesOut)
        external
        nonReentrant
        returns (uint256 yesOut)
    {
        yesOut = getAmountOut(amountIn, noReserve, yesReserve);
        require(yesOut >= minYesOut, "SLIPPAGE");
        uint256 fee = (amountIn * FEE_BPS) / BPS;
        outcomeToken.safeTransferFrom(msg.sender, address(this), noId, amountIn, "");
        noReserve += amountIn - fee;
        yesReserve -= yesOut;
        accumulatedFees += fee;
        outcomeToken.safeTransferFrom(address(this), msg.sender, yesId, yesOut, "");
        emit Swap(msg.sender, noId, amountIn, yesOut);
    }

    function collectFees(address to) external onlyRole(FEE_COLLECTOR_ROLE) returns (uint256 amount) {
        amount = accumulatedFees;
        accumulatedFees = 0;
        emit FeesCollected(to, amount);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    { return IERC1155Receiver.onERC1155Received.selector; }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    { return IERC1155Receiver.onERC1155BatchReceived.selector; }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, IERC165)
        returns (bool)
    { return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId); }
}
