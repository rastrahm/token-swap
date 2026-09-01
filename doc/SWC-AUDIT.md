# Auditoría SWC — Token Swap AMM

Verificación de `TokenSwapPair`, `TokenSwapFactory` y `TokenSwapRouter` contra el [SWC Registry](https://swcregistry.io/) (EIP-1470) y principios del monorepo (custom errors, `ReentrancyGuard`, SafeERC20, K-check).

> **Nota:** El SWC Registry no se mantiene activamente desde ~2020. Complementar con [SCSVS](https://github.com/ComposableSecurity/SCSVS) y [EEA EthTrust](https://entethalliance.org/specs/ethtrust/).

**Contratos auditados:** `src/TokenSwapPair.sol`, `src/TokenSwapFactory.sol`, `src/TokenSwapRouter.sol` (+ interfaces / libs)  
**Fecha:** 2026-09-01  
**Referencia tests:** `test/TokenSwapPair.t.sol`, `test/TokenSwapFactory.t.sol`, `test/TokenSwapRouter.t.sol`, `test/fuzz/`, `test/invariant/`, `test/attack/`, `test/gas/`  
**Gas:** [`GAS.md`](./GAS.md)

---

## Resumen ejecutivo

| Estado | Cantidad |
|--------|----------|
| ✅ Mitigado / No aplicable | 33 |
| ⚠️ Informativo (diseño / MEV / trust) | 3 |
| ❌ Vulnerable | 0 |

**Conclusión:** Sin vulnerabilidades SWC explotables en el alcance del AMM v1 (ERC-20 only, sin flash swaps). Riesgos informativos: MEV/sandwich en swaps públicos (mitigado con `amountOutMin` + `deadline` en Router), donaciones al par (mitigado con `skim`/`sync` y `MINIMUM_LIQUIDITY`), y confianza en orden de tokens en Factory.

**Principios del suite verificados:**

| Principio | Estado |
|-----------|--------|
| Custom errors (no `require` strings) | ✅ |
| Pragma fijo `0.8.24` | ✅ |
| CEI + `nonReentrant` en mint/swap/burn | ✅ + attack suite |
| K-check post-swap (fee 0.3%) | ✅ + unit/fuzz/invariant |
| SafeTransfer (SWC-104) en transfers del par | ✅ |
| TWAP en `_update` con delta de timestamp | ✅ |
| Fuzz ≥ 1000 runs | ✅ `foundry.toml` |
| Invariantes `k` / balances / LP locked | ✅ `test/invariant/` |

---

## Matriz completa SWC-100 — SWC-136

| ID | Título | Aplica | Estado | Evidencia en Token Swap AMM |
|----|--------|--------|--------|------------------------------|
| SWC-100 | Function Default Visibility | Sí | ✅ | Visibilidad explícita en contratos y libs |
| SWC-101 | Integer Overflow and Underflow | Sí | ✅ | Solidity `0.8.24`; producto `k` en `uint256`; reservas `uint112` |
| SWC-102 | Outdated Compiler Version | Sí | ✅ | `pragma solidity 0.8.24` + `foundry.toml` |
| SWC-103 | Floating Pragma | Sí | ✅ | Pragma exacto (sin `^`) |
| SWC-104 | Unchecked Call Return Value | Sí | ✅ | `SafeTransfer` low-level call + bubble-revert |
| SWC-105 | Unprotected Ether Withdrawal | No | N/A | Sin ETH / `payable` / `.call{value}` |
| SWC-106 | Unprotected SELFDESTRUCT | No | N/A | Sin `selfdestruct` |
| SWC-107 | Reentrancy | Sí | ✅ | `nonReentrant` + CEI; `test/attack/ReentrancyAttack.t.sol` |
| SWC-108 | State Variable Default Visibility | Sí | ✅ | Reservas `private`; getters `getReserves` |
| SWC-109 | Uninitialized Storage Pointer | No | N/A | Sin punteros storage legacy |
| SWC-110 | Assert Violation | No | N/A | Sin `assert` de producción |
| SWC-111 | Deprecated Solidity Functions | Sí | ✅ | Sin `suicide` / `throw` / `tx.origin` |
| SWC-112 | Delegatecall to Untrusted Callee | No | N/A | Sin `delegatecall` |
| SWC-113 | DoS with Failed Call | Parcial | ✅ | Transfer ERC-20 fallida → revert completa de swap/burn |
| SWC-114 | Transaction Order Dependence | Sí | ⚠️ | Sandwich / front-run en swaps (MEV); Router `amountOutMin` |
| SWC-115 | Authorization through tx.origin | No | N/A | Sin `tx.origin` |
| SWC-116 | Block values as a proxy for time | Sí | ✅ | TWAP usa `block.timestamp` con wrap uint32 (diseño Uniswap V2) |
| SWC-117 | Signature Malleability | No | N/A | Sin firmas / `ecrecover` / permit |
| SWC-118 | Incorrect Constructor Name | No | N/A | `constructor` 0.8+ |
| SWC-119 | Shadowing State Variables | Sí | ✅ | Locales `reserve0_` / `token0_` en funciones |
| SWC-120 | Weak Sources of Randomness | No | N/A | Sin RNG |
| SWC-121 | Missing Protection against Signature Replay | No | N/A | Sin firmas |
| SWC-122 | Lack of Proper Signature Verification | No | N/A | Sin verificación de firmas |
| SWC-123 | Requirement Violation | Sí | ✅ | Custom errors + unit/fuzz/invariant/attack |
| SWC-124 | Write to Arbitrary Storage Location | No | N/A | Sin assembly de storage arbitrario |
| SWC-125 | Incorrect Inheritance Order | Sí | ✅ | `ITokenSwapPair, TokenSwapERC20, ReentrancyGuard` |
| SWC-126 | Insufficient Gas Griefing | No | N/A | Sin relayers con stipend fijo |
| SWC-127 | Arbitrary Jump with Function Type Variable | No | N/A | Sin function types dinámicos |
| SWC-128 | DoS With Block Gas Limit | Parcial | ✅ | Path fijo 2 tokens; sin loops de usuario |
| SWC-129 | Typographical Error | Sí | ✅ | Revisión + `forge build` / tests |
| SWC-130 | Right-To-Left-Override | No | N/A | ASCII |
| SWC-131 | Presence of unused variables | Sí | ✅ | Sin dead code material |
| SWC-132 | Unexpected Ether balance | No | N/A | Contratos no manejan ETH |
| SWC-133 | Hash Collisions (var-length args) | No | N/A | Sin hashing multi-dinámico propio |
| SWC-134 | Message call with hardcoded gas | No | N/A | Sin `{gas: …}` |
| SWC-135 | Code With No Effects | No | N/A | Sin no-ops relevantes |
| SWC-136 | Unencrypted Private Data On-Chain | Parcial | ✅ | Reservas, precios TWAP y LP son públicos por diseño AMM |

---

## Riesgos informativos

### SWC-114 — MEV y orden de transacciones

Un validador o bot puede insertar swaps alrededor del usuario (`sandwich`), reduciendo el output efectivo.

**Mitigación de producto:** `TokenSwapRouter.swapExactTokensForTokens` con `amountOutMin` y `deadline`; integradores usan slippage conservador y rutas privadas (Flashbots) si aplica.

### Donación al par (inflation attack residual)

Tokens enviados directamente al par sin `mint` incrementan balances vs reservas hasta `sync`/`skim`.

**Mitigación:** `MINIMUM_LIQUIDITY` bloqueada en `address(0)` en primer mint; `skim`/`sync` documentados; invariante `balances >= reserves`.

### Centralización / trust

| Tema | Riesgo | Tratamiento v1 |
|------|--------|----------------|
| Factory única | Pares maliciosos off-suite | Usar factory desplegada conocida |
| Router sin fee switch | Sin protocol fee | By design v1 |
| TWAP manipulable en baja liquidez | Oracle incorrecto | Documentar; TWAP para integradores avanzados |
| Tokens maliciosos (fee-on-transfer) | K-check / accounting | Fuera de alcance v1; solo ERC-20 estándar |

---

## Checklist principios monorepo

| Principio | ¿Cumple? | Notas |
|-----------|----------|--------|
| Custom errors | ✅ | `InvalidK`, `InsufficientLiquidity`, `InsufficientOutputAmount`, … |
| ReentrancyGuard (EIP-1153) | ✅ | mint / swap / burn |
| SafeTransfer / low-level call | ✅ | `src/libraries/SafeTransfer.sol` (bubble-revert) |
| K-check fee 0.3% | ✅ | `balance * 1000 - amountIn * 3` |
| TWAP `_update` | ✅ | `test/TokenSwapPair.Update.t.sol` |
| NatSpec públicas/externas | ✅ | Fase 8 |
| Fuzz ≥ 1000 runs | ✅ | `test/fuzz/TokenSwap.fuzz.t.sol` |
| Invariantes k / balances / LP | ✅ | `test/invariant/` |

---

## Mapeo SWC → tests

| SWC | Test(s) |
|-----|---------|
| SWC-101 | `testFuzz_getAmountOut_*`, `testFuzz_swap_increasesK`, `testFuzz_firstMint_sqrtGeometry`, `invariant_kProductAtLeastGhost` |
| SWC-103 | Compilador fijo (build) |
| SWC-104 | Unit swap/mint/burn; `SafeTransfer` en Pair/Router |
| SWC-107 | `test_Attack_reenterMint_duringSwap_*`, `test_Attack_reenterSwap_*`, `test_Attack_reenterBurn_*` |
| SWC-114 | `testFuzz_router_swap_revertsSlippage`; documental arriba |
| SWC-116 | `test/TokenSwapPair.Update.t.sol` (TWAP acumulación) |
| SWC-123 | unit Pair/Factory/Router + fuzz + invariant + attack |
| K invariant | `invariant_kProductAtLeastGhost`, `invariant_ghostKMatchesReserves`, handler `swapToken*` asserts |

---

## Referencias

- [SWC Registry](https://swcregistry.io/)
- [EIP-1470](https://eips.ethereum.org/EIPS/eip-1470)
- Uniswap V2 (referencia de diseño constant product)
- Gas: [`GAS.md`](./GAS.md)
- Monorepo NFT: [`04-erc721/doc/SWC-AUDIT.md`](../../04-erc721/doc/SWC-AUDIT.md)
