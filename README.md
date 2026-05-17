# TriadMarket — DAO-Governed On-Chain Prediction Market

**Course:** Blockchain Technologies 2 — Final Project  
**Scenario:** Option D — On-Chain Prediction Market  
**Team:** Mukhametkali Dias, Qaldyqan Yerzat, Rudov Andrew

TriadMarket is a full-stack decentralized prediction market protocol. Users can create binary markets, split collateral into ERC-1155 outcome shares, trade shares through a scratch-built constant-product AMM, deposit protocol fees into an ERC-4626 vault, and govern protocol parameters through an OpenZeppelin Governor + Timelock stack.

> This repository is designed as a final-project submission package. Before final submission, run deployment with your own RPC keys and explorer API key, then replace the example addresses in `deployments/` with real verified testnet addresses.

## Team ownership

| Member | Primary ownership | Secondary responsibility |
|---|---|---|
| Mukhametkali Dias | CPMM AMM, ERC-1155 outcome token, ERC-4626 vault | Gas benchmark report |
| Qaldyqan Yerzat | Governor, Timelock, ERC20Votes token, upgradeability | Security audit and Slither remediation |
| Rudov Andrew | Frontend dApp, subgraph, CI/CD | Deployment scripts and documentation |

Every member must understand the full architecture for Q&A.

## Requirement matrix

| Requirement | Implementation |
|---|---|
| UUPS V1 -> V2 upgrade | `UpgradeableTreasury.sol`, `UpgradeableTreasuryV2.sol`, `script/UpgradeTreasury.s.sol` |
| Factory using CREATE and CREATE2 | `MarketFactory.sol` uses `new OutcomeAMM(...)` and `new PredictionMarket{salt: ...}(...)` |
| Inline Yul benchmark | `YulMath.sol`; `benchmarks/yul-benchmark.md` |
| ERC20Votes + ERC20Permit governance token | `TriadToken.sol` |
| ERC-1155 | `OutcomeToken.sol` |
| ERC-4626 vault | `ProtocolFeeVault.sol` |
| DeFi primitive from scratch | `OutcomeAMM.sol` constant product x*y=k, 0.3% fee, slippage protection, LP token |
| Chainlink oracle with staleness check | `ChainlinkPriceOracle.sol`, `mocks/MockV3Aggregator.sol` |
| Subgraph with 4+ entities | `subgraph/schema.graphql`, `subgraph/src/mapping.ts` |
| Governor + Timelock | `TriadGovernor.sol`, `Deploy.s.sol` |
| L2 deployment | `script/Deploy.s.sol`, `script/VerifyPostDeploy.s.sol`, `deployments/*.json` |
| 80+ tests planned | `test/` contains unit, fuzz, invariant, fork, upgrade, and vulnerability tests |
| Security reports | `reports/security-audit.md`, `slither/slither-output.md` |
| Frontend dApp | `frontend/` React + Wagmi/Viem |

## Quick start

```bash
# 1. Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts OpenZeppelin/openzeppelin-contracts-upgradeable foundry-rs/forge-std --no-commit

# 2. Install Node dependencies
npm install
cd frontend && npm install && cd ..

# 3. Format, build, and test
forge fmt
forge build
forge test -vvv
forge coverage --report lcov

# 4. Run static analysis
slither . --config-file slither.config.json

# 5. Deploy to an L2 testnet
cp .env.example .env
# Fill PRIVATE_KEY, RPC URLs, and explorer API key
forge script script/Deploy.s.sol:Deploy --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify -vvvv

# 6. Post-deployment verification
forge script script/VerifyPostDeploy.s.sol:VerifyPostDeploy --rpc-url $ARBITRUM_SEPOLIA_RPC_URL -vvvv
```

## Main user flows

1. **Market creation:** Factory deploys a PredictionMarket through CREATE2 and an AMM through CREATE.
2. **Trading:** User splits collateral into YES/NO ERC-1155 outcome shares, then swaps through the AMM with min-output slippage protection.
3. **Resolution:** Chainlink feed is read through a staleness-checked adapter. Market resolves above/below threshold after the dispute window.
4. **Governance:** Token holders delegate, propose, vote, queue through Timelock, and execute parameter changes.
5. **Fee vault:** Protocol fees are deposited into an ERC-4626 vault for transparent accounting.

## Documentation

- Architecture document: `docs/architecture.md`
- Security audit report: `reports/security-audit.md`
- Gas report: `reports/gas-optimization.md`
- Coverage report: `reports/coverage.md`
- Presentation PDF: `docs/presentation/TriadMarket_Final_Presentation.pdf`

## Important final-submission checklist

- [ ] `forge test` passes locally.
- [ ] `forge coverage` shows at least 90% line coverage for `src/`.
- [ ] Slither shows zero High and zero Medium findings.
- [ ] All contracts are deployed and verified on the selected L2 testnet.
- [ ] README addresses are replaced with real deployed addresses.
- [ ] Frontend `.env` contains real contract and subgraph URLs.
- [ ] Each team member can explain all critical flows.
