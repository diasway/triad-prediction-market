# Coverage Report

Final target required by the assignment: line coverage >= 90% across `contracts/` / `src/`.

Command:

```bash
forge coverage --report lcov
forge coverage --report summary
```

Expected categories:

| Area | Minimum coverage target |
|---|---:|
| MarketFactory | 90% |
| PredictionMarket | 95% |
| OutcomeAMM | 95% |
| ProtocolFeeVault | 90% |
| ChainlinkPriceOracle | 100% |
| Governor deployment configuration | 90% |
| UUPS treasury | 90% |

Paste the generated summary here after running locally or in CI.
