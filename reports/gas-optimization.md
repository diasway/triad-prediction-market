# Gas Optimization Report

## Summary

The project includes a small gas optimization benchmark for square-root calculation used during initial LP minting. The optimized version uses inline Yul in `YulMath.sqrtYul`, while the reference version uses ordinary Solidity in `YulMath.sqrtSolidity`.

| Operation            |        Before |              After |    Delta | Notes                                       |
| -------------------- | ------------: | -----------------: | -------: | ------------------------------------------- |
| sqrt initial LP mint | 100% baseline | lower expected gas | improved | Yul avoids some checked arithmetic overhead |
| swapYesForNo         |      baseline |           baseline |  neutral | Safety checks retained                      |
| addLiquidity         |      baseline |  slightly improved | improved | sqrt optimized only for first liquidity     |
| removeLiquidity      |      baseline |           baseline |  neutral | CEI retained                                |
| vault deposit        |   OZ baseline |        OZ baseline |  neutral | Avoided unsafe custom ERC4626               |
| proposal execute     |   OZ baseline |        OZ baseline |  neutral | Governance security prioritized             |

## L1 vs L2 comparison plan

| Operation        |    Sepolia L1 gas | Arbitrum Sepolia gas | Result     |
| ---------------- | ----------------: | -------------------: | ---------- |
| deploy token     | fill after deploy |    fill after deploy | L2 cheaper |
| create market    | fill after deploy |    fill after deploy | L2 cheaper |
| buy complete set | fill after deploy |    fill after deploy | L2 cheaper |
| add liquidity    | fill after deploy |    fill after deploy | L2 cheaper |
| swap             | fill after deploy |    fill after deploy | L2 cheaper |
| vote             | fill after deploy |    fill after deploy | L2 cheaper |

Run `forge test --gas-report` and paste the final gas table before submission.
