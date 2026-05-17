# TriadMarket Internal Security Audit Report

**Audited project:** TriadMarket DAO-Governed Prediction Market  
**Team:** Mukhametkali Dias, Qaldyqan Yerzat, Rudov Andrew  
**Scope commit:** `FINAL-COMMIT-HASH-TO-BE-FILLED`  
**Date:** Final project submission

## 1. Executive summary

This report documents the internal security review of TriadMarket. The review focused on smart-contract safety, oracle assumptions, governance attack surfaces, access control, reentrancy resistance, accounting consistency, and correctness of the AMM/vault logic.

The protocol includes several defensive patterns: Checks-Effects-Interactions, ReentrancyGuard on external state-changing flows, SafeERC20 for token transfers, AccessControl for privileged actions, Timelock for governance authority, and a Chainlink adapter with staleness checks.

At final submission target, Slither must report zero High and zero Medium findings. Low and Informational items should be listed in the appendix with explicit justification.

## 2. Scope

### In scope

- `src/TriadToken.sol`
- `src/OutcomeToken.sol`
- `src/PredictionMarket.sol`
- `src/OutcomeAMM.sol`
- `src/MarketFactory.sol`
- `src/ProtocolFeeVault.sol`
- `src/ChainlinkPriceOracle.sol`
- `src/TriadGovernor.sol`
- `src/UpgradeableTreasury.sol`
- `src/UpgradeableTreasuryV2.sol`
- vulnerability case studies in `src/case-studies/`

### Out of scope

- Third-party OpenZeppelin contracts.
- Public Chainlink aggregator implementations.
- The Graph hosted service reliability.
- Wallet provider security.

## 3. Methodology

The review used both automated and manual methods:

1. **Static analysis:** Slither with high/medium failure enforced in CI.
2. **Unit testing:** public/external functions and revert paths.
3. **Fuzz testing:** AMM swap input, vault deposit/withdraw, voting power, and math functions.
4. **Invariant testing:** constant-product accounting, vault share accounting, and treasury accounting.
5. **Manual review:** access-control checks, CEI order, external-call return handling, timestamp usage, and oracle assumptions.

## 4. Findings table

| ID | Severity | Title | Location | Status |
|---|---:|---|---|---|
| S-01 | High | Reentrancy in push payout case study | `VulnerablePushPayout.sol` | Fixed in `FixedPullPayout.sol` |
| S-02 | High | Unguarded treasury setter case study | `VulnerableAccessControl.sol` | Fixed in `FixedAccessControl.sol` |
| S-03 | Medium | Stale oracle price can resolve market incorrectly | `ChainlinkPriceOracle.sol` | Fixed |
| S-04 | Medium | Slippage-less AMM swaps expose users to sandwich attacks | `OutcomeAMM.sol` | Fixed |
| S-05 | Low | Open executor role on Timelock | `Deploy.s.sol` | Acknowledged, intentional |
| G-01 | Gas | Solidity sqrt loop more expensive than Yul version | `YulMath.sol` | Optimized |

## 5. Detailed findings

### S-01: Reentrancy in push payout case study

**Severity:** High  
**Location:** `src/case-studies/VulnerablePushPayout.sol`  
**Description:** The vulnerable version performs an external call before setting credit to zero. A malicious receiver can re-enter `withdraw`.  
**Impact:** Contract ETH balance can be drained if multiple users deposited.  
**Proof of concept:** `test/VulnerabilityCaseStudies.t.sol` contains before/after tests.  
**Recommendation:** Apply CEI and ReentrancyGuard.  
**Status:** Fixed in `FixedPullPayout.sol`.

### S-02: Unguarded access-control setter case study

**Severity:** High  
**Location:** `src/case-studies/VulnerableAccessControl.sol`  
**Description:** Any account can change the treasury address.  
**Impact:** Attacker can redirect protocol funds or break accounting.  
**Recommendation:** Use Ownable or AccessControl.  
**Status:** Fixed in `FixedAccessControl.sol`.

### S-03: Stale oracle price can resolve market incorrectly

**Severity:** Medium  
**Location:** `src/ChainlinkPriceOracle.sol`  
**Description:** Oracle values must not be used if the feed is stale.  
**Impact:** Market can resolve using outdated data.  
**Recommendation:** Enforce max-age check and positive answer check.  
**Status:** Fixed. The adapter reverts on stale, negative, or incomplete rounds.

### S-04: Slippage-less AMM swaps expose users to sandwich attacks

**Severity:** Medium  
**Location:** `src/OutcomeAMM.sol`  
**Description:** Without `minOut`, traders cannot constrain execution price.  
**Impact:** MEV bots can manipulate reserves before the trade.  
**Recommendation:** Require `minNoOut`/`minYesOut`.  
**Status:** Fixed.

### S-05: Open executor role on Timelock

**Severity:** Low  
**Location:** `script/Deploy.s.sol`  
**Description:** The Timelock executor role is set to `address(0)`, meaning any account can execute queued operations after the delay.  
**Impact:** No unauthorized operation can be executed, but anyone can pay gas to execute successful queued operations.  
**Recommendation:** Keep as-is for decentralization or restrict to known executors if instructor requests.  
**Status:** Acknowledged.

## 6. Centralization analysis

The production deployment should leave the Timelock as the critical administrator. If an individual deployer retains DEFAULT_ADMIN_ROLE on the Timelock, that is a severe backdoor. The post-deployment verification script explicitly checks that this role is revoked from the deployer.

If a role holder is compromised before governance transfer, the attacker could create markets, pause vault operations, or upgrade the treasury. This is why the recommended deployment process performs role transfer immediately after deployment and records verification output.

## 7. Governance attack analysis

### Flash-loan governance attacks
The token uses ERC20Votes checkpointing. Voting power is measured at the proposal snapshot block, so tokens borrowed after the snapshot cannot influence that proposal.

### Whale attacks
A large holder can still influence governance. The design mitigates this through quorum, proposal threshold, and Timelock delay, but it cannot remove plutocratic risk completely.

### Proposal spam
The 1% proposal threshold makes spam expensive. Frontend can additionally filter proposals by proposer reputation, but contract-level threshold is the main defense.

### Timelock bypass
All privileged production actions should be owned by Timelock. The verification script checks delay and governor proposer permissions.

## 8. Oracle attack analysis

### Price manipulation
The protocol reads Chainlink aggregated feeds rather than a single DEX spot price. This reduces manipulation risk compared with direct pool reserves.

### Stale price
The adapter reverts if `block.timestamp - updatedAt > maxAge`.

### Feed depeg or wrong feed
Deployment documentation must specify exact feed addresses and descriptions. The post-deployment checklist includes manual feed verification.

## 9. External call and ERC20 review

All ERC20 interactions use SafeERC20. ETH transfers in case studies use `call{value:}` with success checks. The production contracts do not use `transfer`, `send`, or `tx.origin` for authorization.

## 10. Appendix: Slither output

See `slither/slither-output.md`. Final submission target: zero High and zero Medium findings.
