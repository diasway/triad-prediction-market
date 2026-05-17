# Inline Yul Benchmark

Benchmark target: compare `YulMath.sqrtSolidity` and `YulMath.sqrtYul`.

Command:

```bash
forge test --match-test test_yulSqrtMatchesSolidity --gas-report
```

The Yul implementation is used for the first LP mint in `OutcomeAMM.addLiquidity`. It is deliberately small and isolated so the assembly block is auditable.
