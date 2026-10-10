# Gas optimization — Token Swap AMM

🇪🇸 [Versión en español](./GAS-ES.md)

Regenerate:

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test --match-contract 'TokenSwapPairTest|TokenSwapRouterTest|TokenSwapFactoryTest|TokenSwapGasTest' --gas-report
forge snapshot --match-contract TokenSwapGasTest
```

**Baseline date:** 2026-09-01 (Phase 8)  
**Snapshot:** `.gas-snapshot` (tests in `test/gas/TokenSwap.gas.t.sol`)

---

## Deploy

| Contract | Before (Phase 7, OZ SafeERC20) | After (Phase 8, SafeTransfer) | Δ |
|----------|--------------------------------|-------------------------------|---|
| `TokenSwapPair` | 1 414 641 gas · 6 754 B | 1 442 552 gas · 6 883 B | +1.9% deploy¹ |
| `TokenSwapRouter` | 994 801 gas · 4 554 B | 1 028 539 gas · 4 710 B | +3.4% deploy¹ |
| `TokenSwapFactory` | (included in `createPair`) | ~1 311 485 gas per pair² | — |

¹ More bytecode due to the custom `SafeTransfer` library (no shared OZ runtime dependency).  
² `testGas_createPair` in the snapshot.

---

## Main functions (gas report, medians)

| Function | Before (avg/med) | After (avg/med) | Runtime Δ | Notes |
|----------|------------------|-----------------|-----------|-------|
| `Pair.mint` | 149 103 | 148 970 | **−133** | `unchecked` subtractions + `token0`/`token1` cache |
| `Pair.swap` | 36 647 | 36 885 | +238 | Scope block to avoid stack-too-deep |
| `Pair.burn` | 57 364 | 57 740 | +376 | Bubble-revert in `SafeTransfer` |
| `Pair.skim` | 57 838 | 58 937 | +1 099 | Conditional transfer only when surplus > 0 |
| `Router.addLiquidity` | 222 201 | 223 296 | +1 095 | E2E path (2× `transferFrom` + `mint`) |
| `Router.swapExactTokensForTokens` | 30 182 | — | — | See e2e snapshot ~280 602 |

---

## E2E snapshot (`test/gas/TokenSwap.gas.t.sol`)

| Test | Gas |
|------|-----|
| `testGas_createPair` | 2 311 485 |
| `testGas_firstMint` | 226 369 |
| `testGas_subsequentMint` | 268 676 |
| `testGas_swap` | 280 602 |
| `testGas_burn` | 273 320 |
| `testGas_skim` | 244 311 |
| `testGas_sync` | 241 731 |

---

## Applied optimizations (Phase 8)

| Technique | Where | Effect |
|-----------|-------|--------|
| `SafeTransfer` (low-level `call` + bubble revert) | Pair, Router | SWC-104; propagates `ReentrancyGuard` on reentry |
| `immutable` `factory` / `token0` / `token1` | Pair, Router | Cheap reads on every operation |
| Packed `uint112` + `uint32` reserves | Pair storage | One fewer slot vs two `uint256` |
| EIP-1153 `ReentrancyGuard` (`tstore`) | Pair | No permanent SSTORE in the guard |
| Bounded `unchecked` arithmetic | `mint`, `burn`, `skim`, `_update` | Less overhead after checks |
| Cached locals `token0_` / `token1_` | `mint`, `sync`, `skim` | Fewer repeated `immutable` reads |
| Conditional `skim` | Pair | Skips transfer when `balance == reserve` |
| `_K_DENOMINATOR` constant | Pair `swap` | Avoids recomputing `1000**2` |
| Custom errors | All | Lower cost than `require` strings |

---

## Accepted tradeoffs

| Decision | Why |
|----------|-----|
| Custom `SafeTransfer` vs OZ `SafeERC20` | Control over bubble-revert + Uniswap V2 pattern; slight deploy increase |
| Scope blocks in `swap` | Avoids `stack too deep` without `viaIR` |
| Intentional `uint32` TWAP overflow | Uniswap V2 compatibility; documented in `_update` |
| Fixed 2-token Router path | No multi-hop loops → predictable gas |
| `optimizer_runs = 200` | Deploy/runtime balance (module Foundry default) |

---

## Security vs gas

| Suite | Role |
|-------|------|
| `test/attack/ReentrancyAttack.t.sol` | SWC-107; bubble-revert preserves the `ReentrancyGuard` selector |
| `test/fuzz/TokenSwap.fuzz.t.sol` | 1000 runs on amounts/slippage/k |
| `test/invariant/TokenSwap.invariant.t.sol` | 256 runs × depth 15 |
| `test/gas/TokenSwap.gas.t.sol` | Reproducible baseline for CI |

Phase 8 suite: **60 green tests** (unit + fuzz + invariant + attack + gas).

See [`SWC-AUDIT-EN.md`](./SWC-AUDIT-EN.md) and [`PLANIFICACION-EN.md`](./PLANIFICACION-EN.md).
