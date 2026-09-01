# Optimización de gas — Token Swap AMM

Regenerar:

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test --match-contract 'TokenSwapPairTest|TokenSwapRouterTest|TokenSwapFactoryTest|TokenSwapGasTest' --gas-report
forge snapshot --match-contract TokenSwapGasTest
```

**Fecha baseline:** 2026-09-01 (Fase 8)  
**Snapshot:** `.gas-snapshot` (tests en `test/gas/TokenSwap.gas.t.sol`)

---

## Deploy

| Contrato | Antes (Fase 7, OZ SafeERC20) | Después (Fase 8, SafeTransfer) | Δ |
|----------|------------------------------|----------------------------------|---|
| `TokenSwapPair` | 1 414 641 gas · 6 754 B | 1 442 552 gas · 6 883 B | +1.9% deploy¹ |
| `TokenSwapRouter` | 994 801 gas · 4 554 B | 1 028 539 gas · 4 710 B | +3.4% deploy¹ |
| `TokenSwapFactory` | (incl. en `createPair`) | ~1 311 485 gas por par² | — |

¹ Más bytecode por librería `SafeTransfer` propia (sin dep compartida OZ en runtime).  
² `testGas_createPair` en snapshot.

---

## Funciones principales (gas-report, medianas)

| Función | Antes (avg/med) | Después (avg/med) | Δ runtime | Notas |
|---------|-----------------|-------------------|-----------|-------|
| `Pair.mint` | 149 103 | 148 970 | **−133** | `unchecked` subs + cache `token0`/`token1` |
| `Pair.swap` | 36 647 | 36 885 | +238 | Scope block anti stack-too-deep |
| `Pair.burn` | 57 364 | 57 740 | +376 | Bubble-revert en `SafeTransfer` |
| `Pair.skim` | 57 838 | 58 937 | +1 099 | Transfer condicional si excedente > 0 |
| `Router.addLiquidity` | 222 201 | 223 296 | +1 095 | Path e2e (2× `transferFrom` + `mint`) |
| `Router.swapExactTokensForTokens` | 30 182 | — | — | Ver snapshot e2e ~280 602 |

---

## Snapshot e2e (`test/gas/TokenSwap.gas.t.sol`)

| Test | Gas |
|------|-----|
| `testGas_createPair` | 2 311 485 |
| `testGas_firstMint` | 226 369 |
| `testGas_subsequentMint` | 268 676 |
| `testGas_swap` | 280 602 |
| `testGas_burn` | 273 320 |
| `testGas_skim` | 244 311 |
| `testGas_sync` | 241 731 |

---

## Optimizaciones aplicadas (Fase 8)

| Técnica | Dónde | Efecto |
|---------|-------|--------|
| `SafeTransfer` (low-level `call` + bubble revert) | Pair, Router | SWC-104; propaga `ReentrancyGuard` en reentrada |
| `immutable` `factory` / `token0` / `token1` | Pair, Router | Lecturas baratas en cada operación |
| Reservas empaquetadas `uint112` + `uint32` | Pair storage | 1 slot menos vs dos `uint256` |
| `ReentrancyGuard` EIP-1153 (`tstore`) | Pair | Sin SSTORE permanente en guard |
| `unchecked` aritmética acotada | `mint`, `burn`, `skim`, `_update` | Menos overhead post-checks |
| Cache locals `token0_` / `token1_` | `mint`, `sync`, `skim` | Menos lecturas `immutable` repetidas |
| `skim` condicional | Pair | Omite transfer si `balance == reserva` |
| Constante `_K_DENOMINATOR` | Pair `swap` | Evita recalcular `1000**2` |
| Custom errors | Todos | Menor coste vs `require` strings |

---

## Tradeoffs aceptados

| Decisión | Por qué |
|----------|---------|
| `SafeTransfer` propio vs OZ `SafeERC20` | Control del bubble-revert + patrón Uniswap V2; ligero aumento de deploy |
| Scope blocks en `swap` | Evita `stack too deep` sin `viaIR` |
| TWAP overflow intencional `uint32` | Compatibilidad Uniswap V2; documentado en `_update` |
| Router path fijo 2 tokens | Sin loops multi-hop → gas predecible |
| `optimizer_runs = 200` | Balance deploy/runtime (Foundry default del módulo) |

---

## Seguridad vs gas

| Suite | Rol |
|-------|-----|
| `test/attack/ReentrancyAttack.t.sol` | SWC-107; bubble-revert preserva selector `ReentrancyGuard` |
| `test/fuzz/TokenSwap.fuzz.t.sol` | 1000 runs amounts/slippage/k |
| `test/invariant/TokenSwap.invariant.t.sol` | 256 runs × depth 15 |
| `test/gas/TokenSwap.gas.t.sol` | Baseline reproducible para CI |

Suite Fase 8: **60 tests** verdes (unit + fuzz + invariant + attack + gas).

Ver [`SWC-AUDIT.md`](./SWC-AUDIT.md) y [`PLANIFICACION.md`](./PLANIFICACION.md).
