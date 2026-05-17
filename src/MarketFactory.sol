// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {OutcomeToken} from "./OutcomeToken.sol";
import {PredictionMarket} from "./PredictionMarket.sol";
import {OutcomeAMM} from "./OutcomeAMM.sol";

contract MarketFactory is AccessControl {
    bytes32 public constant MARKET_CREATOR_ROLE = keccak256("MARKET_CREATOR_ROLE");

    address public immutable collateral;
    address public immutable oracle;
    OutcomeToken public immutable outcomeToken;
    uint256 public nextMarketId = 1;

    struct MarketRecord {
        address market;
        address amm;
        uint256 yesId;
        uint256 noId;
        bytes32 salt;
    }

    mapping(uint256 => MarketRecord) public markets;

    event MarketCreated(uint256 indexed marketId, address market, address amm, uint256 yesId, uint256 noId);

    constructor(address admin, address collateral_, address oracle_) {
        require(admin != address(0) && collateral_ != address(0) && oracle_ != address(0), "ZERO");
        collateral = collateral_;
        oracle = oracle_;
        outcomeToken = new OutcomeToken(address(this)); // CREATE
        outcomeToken.grantRole(outcomeToken.DEFAULT_ADMIN_ROLE(), admin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MARKET_CREATOR_ROLE, admin);
    }

    function createMarket(bytes32 salt, uint256 threshold, uint256 disputeWindowSeconds)
        external
        onlyRole(MARKET_CREATOR_ROLE)
        returns (uint256 marketId, address market, address amm)
    {
        marketId = nextMarketId++;
        uint256 yesId = marketId * 2;
        uint256 noId = marketId * 2 + 1;

        PredictionMarket predictionMarket = new PredictionMarket{salt: salt}(
            msg.sender,
            collateral,
            address(outcomeToken),
            oracle,
            yesId,
            noId,
            threshold,
            disputeWindowSeconds
        ); // CREATE2

        OutcomeAMM outcomeAmm = new OutcomeAMM(
            msg.sender,
            collateral,
            address(outcomeToken),
            yesId,
            noId
        ); // CREATE

        outcomeToken.grantRole(outcomeToken.MINTER_ROLE(), address(predictionMarket));
        outcomeToken.grantRole(outcomeToken.BURNER_ROLE(), address(predictionMarket));

        markets[marketId] = MarketRecord(address(predictionMarket), address(outcomeAmm), yesId, noId, salt);
        emit MarketCreated(marketId, address(predictionMarket), address(outcomeAmm), yesId, noId);
        return (marketId, address(predictionMarket), address(outcomeAmm));
    }

    function predictMarketAddress(bytes32 salt, uint256 threshold, uint256 disputeWindowSeconds)
        external
        view
        returns (address predicted)
    {
        uint256 marketId = nextMarketId;
        uint256 yesId = marketId * 2;
        uint256 noId = marketId * 2 + 1;
        bytes memory bytecode = abi.encodePacked(
            type(PredictionMarket).creationCode,
            abi.encode(msg.sender, collateral, address(outcomeToken), oracle, yesId, noId, threshold, disputeWindowSeconds)
        );
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        predicted = address(uint160(uint256(hash)));
    }
}
