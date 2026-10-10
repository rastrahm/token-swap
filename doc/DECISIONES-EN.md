# Technical decisions, logic and gas — Token Swap AMM

🇪🇸 [Versión en español](./DECISIONES-ES.md)

A reading guide to understand **what was built**, **why**, and **where it can be improved**.  
Complements [`PLANIFICACION-EN.md`](./PLANIFICACION-EN.md), [`GAS-EN.md`](./GAS-EN.md) and [`SWC-AUDIT-EN.md`](./SWC-AUDIT-EN.md).

---

## 1. What this module is (in one sentence)

A **constant product AMM** (`x * y = k`) inspired by Uniswap V2: two ERC-20 tokens, a fixed **0.3%** fee, LP tokens, a **TWAP** oracle, a Router with slippage protection, and a Next.js demo running on Anvil.

It is not a Uniswap fork: it is a learning / portfolio implementation, with tests (unit, fuzz, invariants, attack) and gas and SWC documentation.

---

## 2. Architecture (who does what)

```
User / UI (Next.js)
        │
        ▼
 TokenSwapRouter  ──quote, slippage, deadline, transferFrom──►  Pair
        │                                                       │
        │                                                       ├── mint / burn / swap
        │                                                       ├── reserves + TWAP
        ▼                                                       └── SafeTransfer
 TokenSwapFactory  ──createPair / getPair──►  TokenSwapPair (one per token pair)
```

| Contract | Role |
|----------|------|
| **TokenSwapPair** | Holds tokens, computes LP, executes swaps, verifies K, updates TWAP |
| **TokenSwapFactory** | Creates unique pairs, orders `token0 < token1`, indexes `getPair` |
| **TokenSwapRouter** | UX: approves/transfers from the user, quotes amounts, enforces `amountOutMin` / `deadline` |
| **TokenSwapERC20** | LP token (balances / totalSupply) embedded in the Pair |
| **SafeTransfer** | ERC-20 transfers with low-level `call` + bubble-revert |
| **Math / UQ112x112** | `sqrt` for the first mint; fixed point for TWAP prices |
| **ReentrancyGuard** | EIP-1153 guard (`tstore`) on mint / swap / burn |

**Design decision:** the Pair is "dumb", V2-style (it receives tokens already sent and looks at balances). The Router is the friendly layer for wallets/UI.

---

## 3. Technical decisions (and why)

### 3.1 Market model: constant product

| Decision | Discarded alternative (v1) | Reason |
|----------|----------------------------|--------|
| `x * y = k` with 0.3% fee (997/1000) | Concentrated liquidity (V3), order book | Pedagogical, predictable, well documented |
| One pair = two ERC-20 tokens | Multi-asset pool | Bounded scope |
| Router path = exactly 2 tokens | N-hop multi-hop | Predictable gas, no loops |

### 3.2 Fee and K-check

The swap does not "charge" the fee in a separate contract: it is **embedded** in the K inequality:

1. Outputs are sent (optimistic transfer).
2. `amountIn` is measured from the balance difference.
3. The following is required:

```text
(balance0 * 1000 - amountIn0 * 3) * (balance1 * 1000 - amountIn1 * 3)
  ≥  reserve0 * reserve1 * 1000²
```

This is equivalent to applying a 0.3% fee to the input and requiring that the product of adjusted balances does not drop below the previous reserves.

**Why this way:** same scheme as Uniswap V2; a single check protects against K manipulation and fee bypass.

### 3.3 Liquidity (mint / burn)

| Case | Formula |
|------|---------|
| First mint (`totalSupply == 0`) | `liquidity = √(amount0 · amount1) − MINIMUM_LIQUIDITY` |
| Subsequent mint | `min(amount0 · supply / reserve0, amount1 · supply / reserve1)` |
| Burn | Pro-rata: `amount = liquidity · balance / supply` |

**`MINIMUM_LIQUIDITY = 1000`** is minted to `address(0)` on the first mint: it mitigates residual inflation / donation attacks when the pool is drained to near zero.

### 3.4 TWAP

In `_update()`:

- If time has passed (`timeElapsed > 0`) and there were previous reserves, the price is accumulated into `price0CumulativeLast` / `price1CumulativeLast` (UQ112x112 × time).
- The timestamp is stored as `uint32` (intentional wrap, V2-style).

**Why:** it lets integrators build a time-weighted average price without an external oracle. In v1 there is no on-chain TWAP consumer; only accumulation.

### 3.5 Security

| Decision | Detail |
|----------|--------|
| Fixed pragma `0.8.24` | No floating pragma (SWC-103) |
| Custom errors | Cheaper and typed vs `require("…")` |
| CEI + `nonReentrant` | mint / swap / burn (SWC-107) |
| Custom `SafeTransfer` | Checks return value / bubbles up reverts (SWC-104) |
| No ETH / `payable` / flash swaps | Smaller attack surface in v1 |
| Router: `amountOutMin` + `deadline` | Mitigates slippage / sandwich at the product level (SWC-114 informational) |

### 3.6 Storage and gas (deliberate choices)

| Decision | Effect |
|----------|--------|
| `immutable` factory, token0, token1 | Cheap reads on the hot path |
| `uint112` + `uint32` reserves in one slot | Fewer SSTORE/SLOAD vs two `uint256` |
| EIP-1153 ReentrancyGuard | Guard in transient storage (Cancun) |
| `unchecked` only after validating bounds | Savings without opening overflow |
| Cached locals `token0_` / `token1_` | Avoids re-reading immutables |
| `optimizer_runs = 200` | Deploy ↔ runtime balance |
| `evm_version = cancun` | Required for the guard's `tstore` |

### 3.7 Frontend

| Decision | Reason |
|----------|--------|
| Next.js 15 + ethers v6 | Local demo against Anvil |
| Typed env (Zod) + addresses in `.env.local` | Avoid deployment typos |
| Approve with `MaxUint256` | Fewer popups after the first time |
| Webpack by default (`npm run dev`) | More stable than Turbopack in long sessions |
| ES/EN theme in the static portfolio | Same UX as module 01 |

---

## 4. System logic

### 4.1 Mental flow (user)

```
1. Factory creates the Pair (once per ordered token pair).
2. LP deposits tokenA + tokenB → Router.addLiquidity → Pair.mint → receives LP.
3. Trader swaps → Router.swapExactTokensForTokens → Pair.swap → receives the other token.
4. LP withdraws → Router.removeLiquidity → Pair.burn → receives tokenA + tokenB pro-rata.
```

### 4.2 Mint (detail)

```
Caller (Router) already sent tokens to the Pair
        │
        ▼
Pair.mint(to)
  · reads current balances − reserves = deposited amounts
  · if supply == 0 → sqrt − MINIMUM_LIQUIDITY (locked at address(0))
  · otherwise → min(proportions)
  · _mint(to, liquidity)
  · _update(balances)  → reserves + TWAP
```

### 4.3 Swap (detail)

```
Caller already sent (or will send via Router) the input token to the Pair
        │
        ▼
Pair.swap(amount0Out, amount1Out, to, data)
  · validates outs > 0 and < reserves; to ≠ token0/token1
  · transfers outs to `to` (optimistic)
  · measures amountIn from balances
  · K-check with embedded 0.3% fee
  · _update → Sync + TWAP
```

The `data` parameter exists for V2 parity but **v1 does not execute a callback** (no flash swaps).

### 4.4 Burn (detail)

```
Caller sent LP to the Pair
        │
        ▼
Pair.burn(to)
  · amount0/1 = liquidity · balance / totalSupply
  · _burn(Pair, liquidity)
  · safeTransfer token0/token1 to `to`
  · _update
```

### 4.5 Router (UX layer)

- `addLiquidity`: quotes optimal amounts based on reserves, `transferFrom`s both tokens to the Pair, calls `mint`.
- `swapExactTokensForTokens`: computes `amountOut`, requires `≥ amountOutMin`, `transferFrom`s the input to the Pair, calls `swap`.
- `removeLiquidity`: `transferFrom`s LP to the Pair, calls `burn`, checks minimums.
- `ensure(deadline)`: reverts with `Expired` if the tx arrives late.

### 4.6 Invariants that must hold

| Invariant | Meaning |
|-----------|---------|
| After a swap, adjusted K does not decrease | Fee + anti-manipulation |
| `balances ≥ reserves` (except between transfer and sync) | Pair accounting |
| Locked LP (`MINIMUM_LIQUIDITY`) | Pool cannot be drained to a useful supply of 0 |
| Unique Pair per ordered (tokenA, tokenB) | Factory |

Covered by `test/invariant/` and fuzz.

---

## 5. Can the existing gas usage be improved?

**Yes**, but with tradeoffs. The current state is already good for a didactic V2-like AMM. Below: real improvements, expected impact and cost.

### 5.1 Already applied (Phase 8 baseline)

See the full table in [`GAS-EN.md`](./GAS-EN.md). Summary:

- Immutables, reserve packing, custom errors, bounded `unchecked`, SafeTransfer, EIP-1153, token caching, `_K_DENOMINATOR`.
- Indicative e2e snapshot: swap ~280k gas (including ERC-20 transfers), mint/burn in the ~226k–273k range.

### 5.2 Possible improvements (prioritized)

| # | Idea | Estimated impact | Risk / cost | Worth it in v1? |
|---|------|------------------|-------------|-----------------|
| 1 | Raise `optimizer_runs` (e.g. 1_000–10_000) | −runtime on hot path; ↑ bytecode / deploy | Snapshot must be re-measured | Yes, easy to try |
| 2 | `via_ir = true` + remove scope blocks in `swap` | May lower gas and simplify code | Slower compiles; verify stack | Try on a branch |
| 3 | Assembly / Yul in K-check or UQ112 | Small–medium swap savings | ↓ Readability; more bug surface | Only if aiming for exact V2 parity |
| 4 | Unify `balanceOf` reads (fewer external calls) | Medium (each `balanceOf` costs) | Change CEI order carefully | Review with gas-report |
| 5 | Permit (EIP-2612) on demo tokens + Router | Fewer approve txs in UX (not Pair on-chain gas) | Outside the AMM core | Better in UI/tokens |
| 6 | Linked external `SafeTransfer` library | ↓ size of each contract | Lib deploy + linking | Marginal |
| 7 | Transient storage for more flags / caches | Cancun-friendly | Complexity | Low ROI for now |
| 8 | Compact events (fewer indexed / data) | Small | Worse UX for indexers | Not a priority |
| 9 | Remove TWAP if unused | −SSTORE in `_update` | Loses a module feature | No (it's a module goal) |
| 10 | Multi-hop Router | ↑ UX | ↑ Gas and loops | Out of scope for v1 |

### 5.3 What you should **not** "optimize" blindly

- **Removing `nonReentrant`:** you'd save gas and open SWC-107.
- **Going back to `require` strings:** worse gas and DX.
- **Widening reserves to `uint256` "for clarity":** breaks packing and raises SSTORE.
- **Fee-on-transfer / rebasing tokens:** would change all the accounting; deliberately out of v1.

### 5.4 How to measure any improvement

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test --match-contract TokenSwapGasTest --gas-report
forge snapshot --match-contract TokenSwapGasTest
# compare with .gas-snapshot and update doc/GAS-EN.md / doc/GAS-ES.md
```

Rule of thumb: **do not merge** an "optimization" without a snapshot Δ and without fuzz + invariants + attack staying green.

---

## 6. Quick code ↔ concept map

| Concept | Where to look |
|---------|---------------|
| Mint / swap / burn / TWAP | `src/TokenSwapPair.sol` |
| Pair creation | `src/TokenSwapFactory.sol` |
| Slippage / deadline | `src/TokenSwapRouter.sol` |
| Safe transfers | `src/libraries/SafeTransfer.sol` |
| Reentrancy guard | `src/utils/ReentrancyGuard.sol` |
| Gas baseline | `doc/GAS-EN.md`, `test/gas/`, `.gas-snapshot` |
| SWC matrix | `doc/SWC-AUDIT-EN.md` |
| UI demo | `frontend/` |
| Static portfolio | `portfolio/index.html` |

---

## 7. Executive summary

1. **Decisions:** V2-like AMM, fee inside the K-check, Pair + Factory + Router, security first (CEI, guard, SafeTransfer), gas via packing/immutables/EIP-1153, separate UI.
2. **Logic:** deposit → mint LP; swap by measuring balances and verifying K; withdraw by burning LP; the Router only orchestrates and protects against slippage.
3. **Gas:** there is already a solid baseline; the healthiest improvements are tuning the optimizer/`via_ir` and reducing external calls, always with a snapshot. Don't sacrifice reentrancy protection or the K-check for a few hundred gas.

---

*Last update: aligned with Phases 0–8 + UI of module 06.*
