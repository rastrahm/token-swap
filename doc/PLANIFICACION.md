# Planificación — Module 06: Constant Product AMM (Token Swap)

**Estado:** Fases **0–3** ✅ · fases **4–8** + demo Next.js pendientes.

## 1. Objetivo del proyecto

AMM de **producto constante** (`x * y = k`) con Foundry y Solidity `0.8.24`:

- Swaps entre dos ERC-20 con **fee de protocolo 0.3%**.
- Provisión / retiro de liquidez (`mint` / `burn`) con LP tokens vía geometría `Math.sqrt`.
- Oráculo TWAP: acumulación de `price0CumulativeLast` / `price1CumulativeLast` en `_update()`.
- Seguridad: **CEI**, **ReentrancyGuard**, **custom errors**, transferencias seguras (SafeERC20 / low-level call).
- Verificación post-swap de K: `balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * 1000**2`.
- Demo UI Next.js (swap + add/remove liquidity) según reglas App Router / Zod / Vitest.

---

## 2. Alcance

### Incluye

| Área | Descripción |
|------|-------------|
| Pair | Reservas, swap, mint, burn, `_update`, acumuladores TWAP |
| Factory | Despliegue determinista de pares `token0`/`token1` (ordenados) |
| Math | `sqrt` para liquidez inicial / geometría LP |
| Fee | 0.3% en swaps (997/1000 sobre input) |
| K-check | Invariante ajustada post-swap |
| LP ERC-20 | Mint/burn de shares; MINIMUM_LIQUIDITY a `address(0)` en primer mint |
| Oráculo | TWAP via `price{0,1}CumulativeLast` + `blockTimestampLast` |
| Seguridad | CEI + `nonReentrant` en `swap` / `mint` / `burn`; SafeERC20 |
| Tests | Unit, fuzz (`bound`), invariant `reserve0 * reserve1 >= k` |
| Frontend | Next.js 15 demo — swap + liquidez |

### No incluye (v1)

- Concentrated liquidity / ticks (Uniswap V3).
- Flash swaps con callback arbitraria de terceros (salvo stub interno si se requiere para paridad V2).
- Multi-hop router avanzado (path de N hops); Router v1 solo pair directo + slippage.
- Governance / fee-to dinámico on-chain (fee fijo 0.3%).
- Subgraph / indexación off-chain.

---

## 3. Stack técnico

| Componente | Elección |
|------------|----------|
| Compilador | `pragma solidity 0.8.24;` (exacto) |
| Framework | Foundry (`forge` / fuzz ≥ 1000) |
| Modelo | Constant product `x * y = k` |
| Librerías | OpenZeppelin Contracts v5.x (SafeERC20, ERC20), forge-std; Solmate opcional para gas |
| Transferencias | SafeERC20 / `call` con chequeo de retorno booleano |
| ETH | Si se soporta WETH wrapper: `.call{value}` — nunca `transfer`/`send` |
| UI | Next.js 15 App Router, TypeScript estricto, Zod, Vitest + RTL · Node ≥ 20 |

---

## 4. Arquitectura

```
06-token-swap/
├── doc/                                 # Esta documentación
├── src/
│   ├── TokenSwapPair.sol                # AMM core (swap/mint/burn/TWAP)
│   ├── TokenSwapFactory.sol             # Crea pares ordenados
│   ├── TokenSwapRouter.sol              # Slippage + approve/transferFrom UX
│   ├── interfaces/
│   │   ├── ITokenSwapPair.sol
│   │   ├── ITokenSwapFactory.sol
│   │   └── ITokenSwapRouter.sol
│   ├── libraries/
│   │   ├── Math.sol                     # sqrt
│   │   └── UQ112x112.sol                # fixed-point precios (opcional V2-style)
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

| Actor | Responsabilidad |
|-------|-----------------|
| **LP (Liquidity Provider)** | Deposita token0+token1 → `mint`; quema LP → `burn` |
| **Trader** | Envía input al pair (o vía Router) → `swap` con `amountOutMin` |
| **Factory** | Crea/consulta pares; ordena `token0 < token1` |
| **Pair** | Custodia reservas, emite LP, actualiza TWAP, verifica K |
| **Router** | UX: transferFrom, cálculos de amounts, protección slippage |
| **Oracle consumer** | Lee acumuladores TWAP off-chain / on-chain |

---

## 5. Modelo de datos

```solidity
// TokenSwapPair (resumen de estado)
uint112 private reserve0;
uint112 private reserve1;
uint32  private blockTimestampLast;

uint256 public price0CumulativeLast;
uint256 public price1CumulativeLast;
uint256 public kLast; // opcional si fee-to; en v1 puede omitirse

address public immutable factory;
address public immutable token0;
address public immutable token1;
// + totalSupply / balances LP (ERC-20)
```

- Reservas empaquetadas en un slot (`uint112` + `uint112` + `uint32`).
- Primer `mint`: `liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY`.
- Mint posterior: `min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1)`.
- Swap fee: `amountInWithFee = amountIn * 997`; denominador `1000`.

---

## 6. API on-chain ( Pair )

| Función | Visibilidad | Descripción |
|---------|-------------|-------------|
| `getReserves()` | view | `(reserve0, reserve1, blockTimestampLast)` |
| `mint(to)` | external nonReentrant | Liquidez → LP a `to` |
| `burn(to)` | external nonReentrant | Quema LP del pair → tokens a `to` |
| `swap(amount0Out, amount1Out, to, data)` | external nonReentrant | Swap + K-check + `_update` |
| `sync()` / `skim(to)` | external | Alinear reservas / retirar excedente |
| `_update(...)` | internal | Reservas + TWAP cumulatives |

### Errores custom

`InsufficientOutputAmount` · `InsufficientLiquidity` · `InsufficientInputAmount` · `InvalidK` · `ZeroAddress` · `IdenticalAddresses` · `PairExists` · `Expired` (Router) · `ExcessiveInputAmount` / `InsufficientAAmount` (Router)

### Eventos

`Mint` · `Burn` · `Swap` · `Sync` · `PairCreated` (Factory)

---

## 7. Lógica de swap (fee 0.3% + K)

1. Validar `amount0Out > 0 || amount1Out > 0` y ≤ reservas.
2. Transferir outputs a `to` (CEI: effects de estado tras checks; transfers ordenados con guard).
3. Medir `amountIn` por diferencia de balance vs reservas.
4. Ajuste: `balanceAdjusted = balance * 1000 - amountIn * 3`.
5. Requerir `balance0Adjusted * balance1Adjusted >= uint(reserve0) * reserve1 * 1000**2` → sino `InvalidK`.
6. `_update(balance0, balance1, …)` → TWAP + Sync.

---

## 8. Fases de implementación (TDD)

| Fase | Entregable | Estado |
|------|------------|--------|
| **0** | Scaffold Foundry + docs + interfaces | ✅ |
| **1** | Tests falling: mint / swap / burn / K | ✅ |
| **2** | `Math.sqrt` + `TokenSwapPair` skeleton + `_update` TWAP | ✅ |
| **3** | `mint` (primer depósito + subsequent) + MINIMUM_LIQUIDITY | ✅ |
| **4** | `swap` + fee 0.3% + K-check + ReentrancyGuard | 🔲 |
| **5** | `burn` + `skim` / `sync` | 🔲 |
| **6** | `TokenSwapFactory` + `TokenSwapRouter` (slippage) | 🔲 |
| **7** | Invariant suite + fuzz `bound()` | 🔲 |
| **8** | Gas snapshot + NatSpec + SafeERC20 hardening | 🔲 |
| **UI** | Demo Next.js (swap + add/remove LP) | 🔲 |

---

## 9. Plan de pruebas

| Suite | Ubicación | Cobertura |
|-------|-----------|-----------|
| Unit / e2e | `test/TokenSwapPair.t.sol` | Primer mint vs subsequent, swap, burn, reverts |
| Factory | `test/TokenSwapFactory.t.sol` | Orden tokens, pair único, `getPair` |
| Router | `test/TokenSwapRouter.t.sol` | `amountOutMin`, deadline, path 2 tokens |
| Fuzz | `test/fuzz/TokenSwap.fuzz.t.sol` | Input amounts + slippage con `bound()` |
| Invariant | `test/invariant/TokenSwap.invariant.t.sol` | `reserve0 * reserve1 >= k` tras secuencias |
| UI | `frontend` Vitest | Formularios Zod + roles a11y |

---

## 10. Criterios de aceptación

- [x] Scaffold Foundry (`0.8.24`, fuzz ≥ 1000)
- [ ] TDD mint / swap / burn
- [ ] Fee 0.3% y K-check post-swap
- [ ] TWAP actualizado en `_update` con delta de timestamp
- [ ] CEI + `nonReentrant` en `swap` / `mint` / `burn`
- [ ] Custom errors (sin strings en `require`)
- [ ] SafeERC20 / transfers con revert explícito
- [ ] Invariant `reserve0 * reserve1 >= k`
- [ ] Fuzz con `bound()`
- [ ] NatSpec en funciones public/external
- [ ] Demo frontend (Anvil + swap/LP)

---

## 11. Documentos relacionados

| Documento | Contenido |
|-----------|-----------|
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos de negocio mint/swap/burn |
| [flujograma.md](./flujograma.md) | Operativo + K-check + pipeline TDD |
| [README.md](./README.md) | Índice de `doc/` (crear en fase 0) |

---

## 12. Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Reentrancy en transfer ERC-20 | CEI + `nonReentrant` en mint/swap/burn |
| Tokens non-standard (no return bool) | SafeERC20 / low-level call + check |
| K manipulable / fee bypass | Check `* 1000**2` con ajuste `* 3` fee |
| Overflow en producto de reservas | `uint256` casts; reservas `uint112` |
| Primer LP inflation / donation | `MINIMUM_LIQUIDITY` locked; `skim`/`sync` |
| Slippage sandwich | Router `amountOutMin` + `deadline` |
| TWAP stale / misma block | Acumular solo si `timeElapsed > 0` |

---

## 13. Convenciones (suite + Solidity rules)

- Pragma fijo `0.8.24`; layout: Interfaces → Libraries → Contracts → State → Events → Errors → Modifiers → Functions.
- NatSpec `@notice` / `@dev` / `@param` / `@return` en API pública.
- Tests primero (TDD); `vm.expectRevert` en caminos de fallo.
- Gas: `immutable`/`constant`, packing de reservas, custom errors.
- Frontend (si se implementa): `'use client'`/`'use server'` explícito, Zod, JSDoc, componentes ≤ ~60 líneas, Vitest + RTL por rol.
