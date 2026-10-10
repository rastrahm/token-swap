# SWC Audit — Token Swap AMM

🇪🇸 [Versión en español](./SWC-AUDIT-ES.md)

Review of `TokenSwapPair`, `TokenSwapFactory` and `TokenSwapRouter` against the [SWC Registry](https://swcregistry.io/) (EIP-1470) and monorepo principles (custom errors, `ReentrancyGuard`, SafeERC20, K-check).

> **Note:** The SWC Registry has not been actively maintained since ~2020. Complement it with [SCSVS](https://github.com/ComposableSecurity/SCSVS) and [EEA EthTrust](https://entethalliance.org/specs/ethtrust/).

**Audited contracts:** `src/TokenSwapPair.sol`, `src/TokenSwapFactory.sol`, `src/TokenSwapRouter.sol` (+ interfaces / libs)  
**Date:** 2026-09-01  
**Test references:** `test/TokenSwapPair.t.sol`, `test/TokenSwapFactory.t.sol`, `test/TokenSwapRouter.t.sol`, `test/fuzz/`, `test/invariant/`, `test/attack/`, `test/gas/`  
**Gas:** [`GAS-EN.md`](./GAS-EN.md)

---

## Executive summary

| Status | Count |
|--------|-------|
| ✅ Mitigated / Not applicable | 33 |
| ⚠️ Informational (design / MEV / trust) | 3 |
| ❌ Vulnerable | 0 |

**Conclusion:** No exploitable SWC vulnerabilities within the AMM v1 scope (ERC-20 only, no flash swaps). Informational risks: MEV/sandwich on public swaps (mitigated with `amountOutMin` + `deadline` in the Router), donations to the pair (mitigated with `skim`/`sync` and `MINIMUM_LIQUIDITY`), and trust in token ordering in the Factory.

**Suite principles verified:**

| Principle | Status |
|-----------|--------|
| Custom errors (no `require` strings) | ✅ |
| Fixed pragma `0.8.24` | ✅ |
| CEI + `nonReentrant` on mint/swap/burn | ✅ + attack suite |
| Post-swap K-check (0.3% fee) | ✅ + unit/fuzz/invariant |
| SafeTransfer (SWC-104) on pair transfers | ✅ |
| TWAP in `_update` with timestamp delta | ✅ |
| Fuzz ≥ 1000 runs | ✅ `foundry.toml` |
| Invariants `k` / balances / locked LP | ✅ `test/invariant/` |

---

## Full matrix SWC-100 — SWC-136

| ID | Title | Applies | Status | Evidence in Token Swap AMM |
|----|-------|---------|--------|----------------------------|
| SWC-100 | Function Default Visibility | Yes | ✅ | Explicit visibility in contracts and libs |
| SWC-101 | Integer Overflow and Underflow | Yes | ✅ | Solidity `0.8.24`; `k` product in `uint256`; `uint112` reserves |
| SWC-102 | Outdated Compiler Version | Yes | ✅ | `pragma solidity 0.8.24` + `foundry.toml` |
| SWC-103 | Floating Pragma | Yes | ✅ | Exact pragma (no `^`) |
| SWC-104 | Unchecked Call Return Value | Yes | ✅ | `SafeTransfer` low-level call + bubble-revert |
| SWC-105 | Unprotected Ether Withdrawal | No | N/A | No ETH / `payable` / `.call{value}` |
| SWC-106 | Unprotected SELFDESTRUCT | No | N/A | No `selfdestruct` |
| SWC-107 | Reentrancy | Yes | ✅ | `nonReentrant` + CEI; `test/attack/ReentrancyAttack.t.sol` |
| SWC-108 | State Variable Default Visibility | Yes | ✅ | `private` reserves; `getReserves` getter |
| SWC-109 | Uninitialized Storage Pointer | No | N/A | No legacy storage pointers |
| SWC-110 | Assert Violation | No | N/A | No production `assert` |
| SWC-111 | Deprecated Solidity Functions | Yes | ✅ | No `suicide` / `throw` / `tx.origin` |
| SWC-112 | Delegatecall to Untrusted Callee | No | N/A | No `delegatecall` |
| SWC-113 | DoS with Failed Call | Partial | ✅ | Failed ERC-20 transfer → full revert of swap/burn |
| SWC-114 | Transaction Order Dependence | Yes | ⚠️ | Sandwich / front-running on swaps (MEV); Router `amountOutMin` |
| SWC-115 | Authorization through tx.origin | No | N/A | No `tx.origin` |
| SWC-116 | Block values as a proxy for time | Yes | ✅ | TWAP uses `block.timestamp` with uint32 wrap (Uniswap V2 design) |
| SWC-117 | Signature Malleability | No | N/A | No signatures / `ecrecover` / permit |
| SWC-118 | Incorrect Constructor Name | No | N/A | 0.8+ `constructor` |
| SWC-119 | Shadowing State Variables | Yes | ✅ | Locals `reserve0_` / `token0_` inside functions |
| SWC-120 | Weak Sources of Randomness | No | N/A | No RNG |
| SWC-121 | Missing Protection against Signature Replay | No | N/A | No signatures |
| SWC-122 | Lack of Proper Signature Verification | No | N/A | No signature verification |
| SWC-123 | Requirement Violation | Yes | ✅ | Custom errors + unit/fuzz/invariant/attack |
| SWC-124 | Write to Arbitrary Storage Location | No | N/A | No arbitrary storage assembly |
| SWC-125 | Incorrect Inheritance Order | Yes | ✅ | `ITokenSwapPair, TokenSwapERC20, ReentrancyGuard` |
| SWC-126 | Insufficient Gas Griefing | No | N/A | No relayers with fixed stipend |
| SWC-127 | Arbitrary Jump with Function Type Variable | No | N/A | No dynamic function types |
| SWC-128 | DoS With Block Gas Limit | Partial | ✅ | Fixed 2-token path; no user-controlled loops |
| SWC-129 | Typographical Error | Yes | ✅ | Review + `forge build` / tests |
| SWC-130 | Right-To-Left-Override | No | N/A | ASCII |
| SWC-131 | Presence of unused variables | Yes | ✅ | No material dead code |
| SWC-132 | Unexpected Ether balance | No | N/A | Contracts do not handle ETH |
| SWC-133 | Hash Collisions (var-length args) | No | N/A | No custom multi-dynamic hashing |
| SWC-134 | Message call with hardcoded gas | No | N/A | No `{gas: …}` |
| SWC-135 | Code With No Effects | No | N/A | No relevant no-ops |
| SWC-136 | Unencrypted Private Data On-Chain | Partial | ✅ | Reserves, TWAP prices and LP are public by AMM design |

---

## Informational risks

### SWC-114 — MEV and transaction ordering

A validator or bot can insert swaps around the user (`sandwich`), reducing the effective output.

**Product mitigation:** `TokenSwapRouter.swapExactTokensForTokens` with `amountOutMin` and `deadline`; integrators use conservative slippage and private routes (Flashbots) where applicable.

### Donation to the pair (residual inflation attack)

Tokens sent directly to the pair without `mint` increase balances vs reserves until `sync`/`skim`.

**Mitigation:** `MINIMUM_LIQUIDITY` locked at `address(0)` on the first mint; `skim`/`sync` documented; `balances >= reserves` invariant.

### Centralization / trust

| Topic | Risk | v1 treatment |
|-------|------|--------------|
| Single factory | Malicious off-suite pairs | Use the known deployed factory |
| Router without fee switch | No protocol fee | By design in v1 |
| TWAP manipulable at low liquidity | Wrong oracle price | Documented; TWAP intended for advanced integrators |
| Malicious tokens (fee-on-transfer) | K-check / accounting | Out of scope for v1; standard ERC-20 only |

---

## Monorepo principles checklist

| Principle | Compliant? | Notes |
|-----------|------------|-------|
| Custom errors | ✅ | `InvalidK`, `InsufficientLiquidity`, `InsufficientOutputAmount`, … |
| ReentrancyGuard (EIP-1153) | ✅ | mint / swap / burn |
| SafeTransfer / low-level call | ✅ | `src/libraries/SafeTransfer.sol` (bubble-revert) |
| 0.3% fee K-check | ✅ | `balance * 1000 - amountIn * 3` |
| TWAP `_update` | ✅ | `test/TokenSwapPair.Update.t.sol` |
| NatSpec on public/external | ✅ | Phase 8 |
| Fuzz ≥ 1000 runs | ✅ | `test/fuzz/TokenSwap.fuzz.t.sol` |
| k / balances / LP invariants | ✅ | `test/invariant/` |

---

## SWC → tests mapping

| SWC | Test(s) |
|-----|---------|
| SWC-101 | `testFuzz_getAmountOut_*`, `testFuzz_swap_increasesK`, `testFuzz_firstMint_sqrtGeometry`, `invariant_kProductAtLeastGhost` |
| SWC-103 | Fixed compiler (build) |
| SWC-104 | Unit swap/mint/burn; `SafeTransfer` in Pair/Router |
| SWC-107 | `test_Attack_reenterMint_duringSwap_*`, `test_Attack_reenterSwap_*`, `test_Attack_reenterBurn_*` |
| SWC-114 | `testFuzz_router_swap_revertsSlippage`; documented above |
| SWC-116 | `test/TokenSwapPair.Update.t.sol` (TWAP accumulation) |
| SWC-123 | Pair/Factory/Router unit + fuzz + invariant + attack |
| K invariant | `invariant_kProductAtLeastGhost`, `invariant_ghostKMatchesReserves`, handler `swapToken*` asserts |

---

## References

- [SWC Registry](https://swcregistry.io/)
- [EIP-1470](https://eips.ethereum.org/EIPS/eip-1470)
- Uniswap V2 (constant product design reference)
- Gas: [`GAS-EN.md`](./GAS-EN.md)
- NFT monorepo: [`04-erc721/doc/SWC-AUDIT-EN.md`](../../04-erc721/doc/SWC-AUDIT-EN.md)
