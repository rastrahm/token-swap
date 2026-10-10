# Planning — Module 06: Constant Product AMM (Token Swap)

🇪🇸 [Versión en español](./PLANIFICACION-ES.md)

**Status:** Phases **0–8** ✅ + **UI** ✅ (Next.js demo with light/dark theme).

## 1. Project goal

**Constant product** AMM (`x * y = k`) with Foundry and Solidity `0.8.24`:

- Swaps between two ERC-20 tokens with a **0.3% protocol fee**.
- Liquidity provision / withdrawal (`mint` / `burn`) with LP tokens via `Math.sqrt` geometry.
- TWAP oracle: accumulation of `price0CumulativeLast` / `price1CumulativeLast` in `_update()`.
- Security: **CEI**, **ReentrancyGuard**, **custom errors**, safe transfers (SafeERC20 / low-level call).
- Post-swap K verification: `balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * 1000**2`.
- Next.js demo UI (swap + add/remove liquidity) following App Router / Zod / Vitest rules.

---

## 2. Scope

### Included

| Area | Description |
|------|-------------|
| Pair | Reserves, swap, mint, burn, `_update`, TWAP accumulators |
| Factory | Deterministic deployment of ordered `token0`/`token1` pairs |
| Math | `sqrt` for initial liquidity / LP geometry |
| Fee | 0.3% on swaps (997/1000 on input) |
| K-check | Adjusted post-swap invariant |
| LP ERC-20 | Share mint/burn; MINIMUM_LIQUIDITY to `address(0)` on first mint |
| Oracle | TWAP via `price{0,1}CumulativeLast` + `blockTimestampLast` |
| Security | CEI + `nonReentrant` on `swap` / `mint` / `burn`; SafeERC20 |
| Tests | Unit, fuzz (`bound`), invariant `reserve0 * reserve1 >= k` |
| Frontend | Next.js 15 demo — swap + liquidity |

### Not included (v1)

- Concentrated liquidity / ticks (Uniswap V3).
- Flash swaps with arbitrary third-party callbacks (except an internal stub if needed for V2 parity).
- Advanced multi-hop router (N-hop paths); Router v1 only handles a direct pair + slippage.
- Governance / dynamic on-chain fee-to (fixed 0.3% fee).
- Subgraph / off-chain indexing.

---

## 3. Tech stack

| Component | Choice |
|-----------|--------|
| Compiler | `pragma solidity 0.8.24;` (exact) |
| Framework | Foundry (`forge` / fuzz ≥ 1000) |
| Model | Constant product `x * y = k` |
| Libraries | OpenZeppelin Contracts v5.x (SafeERC20, ERC20), forge-std; Solmate optional for gas |
| Transfers | SafeERC20 / `call` with boolean return check |
| ETH | If a WETH wrapper is supported: `.call{value}` — never `transfer`/`send` |
| UI | Next.js 15 App Router, strict TypeScript, Zod, Vitest + RTL · Node ≥ 20 |

---

## 4. Architecture

```
06-token-swap/
├── doc/                                 # This documentation
├── src/
│   ├── TokenSwapPair.sol                # AMM core (swap/mint/burn/TWAP)
│   ├── TokenSwapFactory.sol             # Creates ordered pairs
│   ├── TokenSwapRouter.sol              # Slippage + approve/transferFrom UX
│   ├── interfaces/
│   │   ├── ITokenSwapPair.sol
│   │   ├── ITokenSwapFactory.sol
│   │   └── ITokenSwapRouter.sol
│   ├── libraries/
│   │   ├── Math.sol                     # sqrt
│   │   └── UQ112x112.sol                # fixed-point prices (optional, V2-style)
│   └── mocks/MockERC20.sol
├── test/
│   ├── TokenSwapPair.t.sol              # Unit: mint/swap/burn
│   ├── TokenSwapFactory.t.sol
│   ├── fuzz/TokenSwap.fuzz.t.sol
│   ├── invariant/TokenSwap.invariant.t.sol
│   └── mocks/
├── script/Deploy.s.sol
├── frontend/                            # Next.js App Router
├── foundry.toml
└── remappings.txt
```

### Roles

| Actor | Responsibility |
|-------|----------------|
| **LP (Liquidity Provider)** | Deposits token0+token1 → `mint`; burns LP → `burn` |
| **Trader** | Sends input to the pair (or via Router) → `swap` with `amountOutMin` |
| **Factory** | Creates/queries pairs; orders `token0 < token1` |
| **Pair** | Holds reserves, issues LP, updates TWAP, verifies K |
| **Router** | UX: transferFrom, amount calculations, slippage protection |
| **Oracle consumer** | Reads TWAP accumulators off-chain / on-chain |

---

## 5. Data model

```solidity
// TokenSwapPair (state summary)
uint112 private reserve0;
uint112 private reserve1;
uint32  private blockTimestampLast;

uint256 public price0CumulativeLast;
uint256 public price1CumulativeLast;
uint256 public kLast; // optional with fee-to; may be omitted in v1

address public immutable factory;
address public immutable token0;
address public immutable token1;
// + LP totalSupply / balances (ERC-20)
```

- Reserves packed into one slot (`uint112` + `uint112` + `uint32`).
- First `mint`: `liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY`.
- Subsequent mint: `min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1)`.
- Swap fee: `amountInWithFee = amountIn * 997`; denominator `1000`.

---

## 6. On-chain API (Pair)

| Function | Visibility | Description |
|----------|------------|-------------|
| `getReserves()` | view | `(reserve0, reserve1, blockTimestampLast)` |
| `mint(to)` | external nonReentrant | Liquidity → LP to `to` |
| `burn(to)` | external nonReentrant | Burns the pair's LP → tokens to `to` |
| `swap(amount0Out, amount1Out, to, data)` | external nonReentrant | Swap + K-check + `_update` |
| `sync()` / `skim(to)` | external | Align reserves / withdraw surplus |
| `_update(...)` | internal | Reserves + TWAP cumulatives |

### Custom errors

`InsufficientOutputAmount` · `InsufficientLiquidity` · `InsufficientInputAmount` · `InvalidK` · `ZeroAddress` · `IdenticalAddresses` · `PairExists` · `Expired` (Router) · `ExcessiveInputAmount` / `InsufficientAAmount` (Router)

### Events

`Mint` · `Burn` · `Swap` · `Sync` · `PairCreated` (Factory)

---

## 7. Swap logic (0.3% fee + K)

1. Validate `amount0Out > 0 || amount1Out > 0` and ≤ reserves.
2. Transfer outputs to `to` (CEI: state effects after checks; transfers ordered under the guard).
3. Measure `amountIn` from the balance vs reserve difference.
4. Adjustment: `balanceAdjusted = balance * 1000 - amountIn * 3`.
5. Require `balance0Adjusted * balance1Adjusted >= uint(reserve0) * reserve1 * 1000**2` → otherwise `InvalidK`.
6. `_update(balance0, balance1, …)` → TWAP + Sync.

---

## 8. Implementation phases (TDD)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| **0** | Foundry scaffold + docs + interfaces | ✅ |
| **1** | Failing tests: mint / swap / burn / K | ✅ |
| **2** | `Math.sqrt` + `TokenSwapPair` skeleton + `_update` TWAP | ✅ |
| **3** | `mint` (first deposit + subsequent) + MINIMUM_LIQUIDITY | ✅ |
| **4** | `swap` + 0.3% fee + K-check + ReentrancyGuard | ✅ |
| **5** | `burn` + `skim` / `sync` | ✅ |
| **6** | `TokenSwapFactory` + `TokenSwapRouter` (slippage) | ✅ |
| **7** | Invariant suite + `bound()` fuzz + SWC-AUDIT | ✅ |
| **8** | Gas snapshot + NatSpec + SafeTransfer hardening | ✅ |
| **UI** | Next.js demo (swap + add/remove LP) | ✅ |

---

## 9. Test plan

| Suite | Location | Coverage |
|-------|----------|----------|
| Unit / e2e | `test/TokenSwapPair.t.sol` | First vs subsequent mint, swap, burn, reverts |
| Factory | `test/TokenSwapFactory.t.sol` | Token ordering, unique pair, `getPair` |
| Router | `test/TokenSwapRouter.t.sol` | `amountOutMin`, deadline, 2-token path |
| Fuzz | `test/fuzz/TokenSwap.fuzz.t.sol` | Input amounts + slippage with `bound()` |
| Invariant | `test/invariant/TokenSwap.invariant.t.sol` | `reserve0 * reserve1 >= k` across sequences |
| Gas | `test/gas/TokenSwap.gas.t.sol` | E2E snapshot mint/swap/burn/skim/sync |
| UI | `frontend` Vitest | Zod forms + a11y roles |

---

## 10. Acceptance criteria

- [x] Foundry scaffold (`0.8.24`, fuzz ≥ 1000)
- [x] TDD mint / swap / burn
- [x] 0.3% fee and post-swap K-check
- [x] TWAP updated in `_update` with timestamp delta
- [x] CEI + `nonReentrant` on `swap` / `mint` / `burn`
- [x] Custom errors (no strings in `require`)
- [x] SafeERC20 / transfers with explicit revert
- [x] Invariant `reserve0 * reserve1 >= k`
- [x] Fuzz with `bound()`
- [x] SWC audit (`doc/SWC-AUDIT-EN.md`)
- [x] NatSpec on public/external functions
- [x] Gas baseline (`doc/GAS-EN.md` + `.gas-snapshot`)
- [x] Hardened `SafeTransfer` (bubble-revert SWC-104)
- [x] Frontend demo (Anvil + swap/LP + light/dark theme)

---

## 11. Related documents

| Document | Content |
|----------|---------|
| [diagrama-clases-EN.md](./diagrama-clases-EN.md) | Contract / lib / test / UI UML |
| [diagrama-flujo-EN.md](./diagrama-flujo-EN.md) | Mint/swap/burn business flows |
| [flujograma-EN.md](./flujograma-EN.md) | Operations + K-check + TDD pipeline |
| [README-EN.md](./README-EN.md) | `doc/` index |

---

## 12. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Reentrancy during ERC-20 transfer | CEI + `nonReentrant` on mint/swap/burn |
| Non-standard tokens (no bool return) | SafeERC20 / low-level call + check |
| K manipulation / fee bypass | `* 1000**2` check with `* 3` fee adjustment |
| Overflow in reserve product | `uint256` casts; `uint112` reserves |
| First-LP inflation / donation | Locked `MINIMUM_LIQUIDITY`; `skim`/`sync` |
| Sandwich slippage | Router `amountOutMin` + `deadline` |
| Stale TWAP / same block | Accumulate only if `timeElapsed > 0` |

---

## 13. Conventions (suite + Solidity rules)

- Fixed pragma `0.8.24`; layout: Interfaces → Libraries → Contracts → State → Events → Errors → Modifiers → Functions.
- NatSpec `@notice` / `@dev` / `@param` / `@return` on the public API.
- Tests first (TDD); `vm.expectRevert` on failure paths.
- Gas: `immutable`/`constant`, reserve packing, custom errors.
- Frontend (if implemented): explicit `'use client'`/`'use server'`, Zod, JSDoc, components ≤ ~60 lines, Vitest + RTL by role.
