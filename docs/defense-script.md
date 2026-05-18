# 15-Minute Defense Script

## Dias — protocol and AMM

Our project is TriadMarket, an on-chain binary prediction market. We chose Option D. The core market creates two ERC-1155 outcome tokens, YES and NO. Users can split collateral into both outcomes, then trade those outcome shares through our own constant-product AMM. The AMM uses the formula x\*y=k, charges a 0.3% fee, and requires min-output slippage protection. This protects users from receiving less than expected during volatile reserve changes.

## Qaldyqan — governance, oracle, security

The protocol is governed by TRIAD, which is an ERC20Votes and ERC20Permit token. We use OpenZeppelin Governor with TimelockController. The voting delay is one day, voting period is one week, quorum is four percent, proposal threshold is one percent, and Timelock delay is two days. For resolution, we use a Chainlink oracle adapter. The adapter rejects negative, incomplete, or stale prices.

## Andrew — frontend, subgraph, DevOps

The frontend connects through MetaMask and WalletConnect. It reads token balance, voting power, delegate address, protocol market state, and subgraph data. It supports state-changing actions like delegate, vote, deposit, and swap. The subgraph indexes markets, trades, liquidity positions, vault deposits, and proposal snapshots. CI runs formatting, build, tests, coverage, Slither, and frontend build.

## Closing

The most important engineering point is that this is not only a set of contracts. It is a complete protocol package with deployment scripts, audit report, architecture document, gas report, frontend, subgraph, and governance flow.
