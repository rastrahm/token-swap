# Decisiones técnicas, lógica y gas — Token Swap AMM

🇬🇧 [English version](./DECISIONES-EN.md)

Documento de lectura para entender **qué se hizo**, **por qué** y **dónde se puede mejorar**.  
Complementa [`PLANIFICACION-ES.md`](./PLANIFICACION-ES.md), [`GAS-ES.md`](./GAS-ES.md) y [`SWC-AUDIT-ES.md`](./SWC-AUDIT-ES.md).

---

## 1. Qué es este módulo (en una frase)

Un **AMM de producto constante** (`x * y = k`) inspirado en Uniswap V2: dos ERC-20, fee fijo **0.3%**, LP tokens, oráculo **TWAP**, Router con slippage, y una demo Next.js sobre Anvil.

No es un fork de Uniswap: es una implementación de aprendizaje / portafolio, con tests (unit, fuzz, invariantes, attack) y documentación de gas y SWC.

---

## 2. Arquitectura (quién hace qué)

```
Usuario / UI (Next.js)
        │
        ▼
 TokenSwapRouter  ──quote, slippage, deadline, transferFrom──►  Pair
        │                                                       │
        │                                                       ├── mint / burn / swap
        │                                                       ├── reservas + TWAP
        ▼                                                       └── SafeTransfer
 TokenSwapFactory  ──createPair / getPair──►  TokenSwapPair (uno por par de tokens)
```

| Contrato | Rol |
|----------|-----|
| **TokenSwapPair** | Custodia tokens, calcula LP, ejecuta swap, verifica K, actualiza TWAP |
| **TokenSwapFactory** | Crea pares únicos, ordena `token0 < token1`, indexa `getPair` |
| **TokenSwapRouter** | UX: aprueba/transfiere desde el usuario, cotiza amounts, aplica `amountOutMin` / `deadline` |
| **TokenSwapERC20** | LP token (balances / totalSupply) embebido en el Pair |
| **SafeTransfer** | Transferencias ERC-20 con low-level `call` + bubble-revert |
| **Math / UQ112x112** | `sqrt` para primer mint; punto fijo para precios TWAP |
| **ReentrancyGuard** | Guard EIP-1153 (`tstore`) en mint / swap / burn |

**Decisión de diseño:** el Pair es “dumb” al estilo V2 (recibe tokens ya enviados y mira balances). El Router es la capa amigable para wallets/UI.

---

## 3. Decisiones técnicas (y por qué)

### 3.1 Modelo de mercado: constant product

| Decisión | Alternativa descartada (v1) | Motivo |
|----------|-----------------------------|--------|
| `x * y = k` con fee 0.3% (997/1000) | Concentrated liquidity (V3), order book | Pedagógico, predecible, bien documentado |
| Un par = dos tokens ERC-20 | Multi-asset pool | Alcance acotado |
| Path de Router = exactamente 2 tokens | Multi-hop N hops | Gas predecible, sin loops |

### 3.2 Fee y K-check

En el swap no se “cobra” el fee en un contrato aparte: se **embebe** en la desigualdad de K:

1. Se envían los outputs (transfer optimista).
2. Se mide el `amountIn` por diferencia de balances.
3. Se exige:

```text
(balance0 * 1000 - amountIn0 * 3) * (balance1 * 1000 - amountIn1 * 3)
  ≥  reserve0 * reserve1 * 1000²
```

Eso equivale a aplicar fee 0.3% sobre el input y exigir que el producto de balances ajustados no baje respecto a las reservas previas.

**Por qué así:** mismo esquema que Uniswap V2; un solo check protege manipulación de K y fee bypass.

### 3.3 Liquidez (mint / burn)

| Caso | Fórmula |
|------|---------|
| Primer mint (`totalSupply == 0`) | `liquidity = √(amount0 · amount1) − MINIMUM_LIQUIDITY` |
| Mint posterior | `min(amount0 · supply / reserve0, amount1 · supply / reserve1)` |
| Burn | Pro-rata: `amount = liquidity · balance / supply` |

**`MINIMUM_LIQUIDITY = 1000`** se acuña a `address(0)` en el primer mint: mitiga inflation / donation attacks residuales al vaciar el pool a casi cero.

### 3.4 TWAP

En `_update()`:

- Si pasó tiempo (`timeElapsed > 0`) y había reservas previas, se acumula precio en `price0CumulativeLast` / `price1CumulativeLast` (UQ112x112 × tiempo).
- Timestamp se guarda como `uint32` (wrap intencional, estilo V2).

**Por qué:** permite a integradores construir un precio medio ponderado en el tiempo sin oráculo externo. En v1 no hay consumidor on-chain del TWAP; solo acumulación.

### 3.5 Seguridad

| Decisión | Detalle |
|----------|---------|
| Pragma fijo `0.8.24` | Sin floating pragma (SWC-103) |
| Custom errors | Más baratos y tipados que `require("…")` |
| CEI + `nonReentrant` | mint / swap / burn (SWC-107) |
| `SafeTransfer` propio | Chequea retorno / burbujea revert (SWC-104) |
| Sin ETH / `payable` / flash swaps | Reduce superficie de ataque en v1 |
| Router: `amountOutMin` + `deadline` | Mitiga slippage / sandwich a nivel producto (SWC-114 informativo) |

### 3.6 Storage y gas (decididos a propósito)

| Decisión | Efecto |
|----------|--------|
| `immutable` factory, token0, token1 | Lecturas baratas en hot path |
| Reservas `uint112` + `uint32` en un slot | Menos SSTORE/SLOAD vs dos `uint256` |
| ReentrancyGuard EIP-1153 | Guard en transient storage (Cancun) |
| `unchecked` solo tras validar bounds | Ahorro sin abrir overflow |
| Cache locals `token0_` / `token1_` | Evita releer immutables |
| `optimizer_runs = 200` | Balance deploy ↔ runtime |
| `evm_version = cancun` | Necesario para `tstore` del guard |

### 3.7 Frontend

| Decisión | Motivo |
|----------|--------|
| Next.js 15 + ethers v6 | Demo local contra Anvil |
| Env tipado (Zod) + addresses en `.env.local` | Evitar typos de deploy |
| Approve con `MaxUint256` | Menos popups tras la primera vez |
| Webpack por defecto (`npm run dev`) | Más estable que Turbopack en sesiones largas |
| Tema ES/EN en portfolio estático | Misma UX que módulo 01 |

---

## 4. Lógica que sigue el sistema

### 4.1 Flujo mental (usuario)

```
1. Factory crea el Pair (una vez por par de tokens ordenados).
2. LP deposita tokenA + tokenB → Router.addLiquidity → Pair.mint → recibe LP.
3. Trader hace swap → Router.swapExactTokensForTokens → Pair.swap → recibe el otro token.
4. LP retira → Router.removeLiquidity → Pair.burn → recibe tokenA + tokenB pro-rata.
```

### 4.2 Mint (detalle)

```
Caller (Router) ya envió tokens al Pair
        │
        ▼
Pair.mint(to)
  · lee balances actuales − reservas = amounts depositados
  · si supply == 0 → sqrt − MINIMUM_LIQUIDITY (lock a address(0))
  · si no → min(proporciones)
  · _mint(to, liquidity)
  · _update(balances)  → reservas + TWAP
```

### 4.3 Swap (detalle)

```
Caller ya envió (o enviará vía Router) el token de entrada al Pair
        │
        ▼
Pair.swap(amount0Out, amount1Out, to, data)
  · valida outs > 0 y < reservas; to ≠ token0/token1
  · transfiere outs a `to` (optimista)
  · mide amountIn por balances
  · K-check con fee 0.3% embebido
  · _update → Sync + TWAP
```

El parámetro `data` existe por paridad V2 pero **v1 no ejecuta callback** (sin flash swaps).

### 4.4 Burn (detalle)

```
Caller envió LP al Pair
        │
        ▼
Pair.burn(to)
  · amount0/1 = liquidity · balance / totalSupply
  · _burn(Pair, liquidity)
  · safeTransfer token0/token1 a `to`
  · _update
```

### 4.5 Router (capa UX)

- `addLiquidity`: cotiza amounts óptimos según reservas, `transferFrom` de ambos tokens al Pair, llama `mint`.
- `swapExactTokensForTokens`: calcula `amountOut`, exige `≥ amountOutMin`, `transferFrom` input al Pair, llama `swap`.
- `removeLiquidity`: `transferFrom` LP al Pair, llama `burn`, chequea mínimos.
- `ensure(deadline)`: revierte `Expired` si la tx llega tarde.

### 4.6 Invariantes que deben mantenerse

| Invariante | Significado |
|------------|-------------|
| Tras swap, K ajustada no baja | Fee + anti-manipulación |
| `balances ≥ reserves` (salvo entre transfer y sync) | Contabilidad del par |
| LP locked (`MINIMUM_LIQUIDITY`) | No vaciar el pool a supply 0 útil |
| Pair único por (tokenA, tokenB) ordenados | Factory |

Cubiertas por `test/invariant/` y fuzz.

---

## 5. ¿Se puede mejorar el gas de lo que existe?

**Sí**, pero con tradeoffs. Lo actual ya está en un buen punto para un AMM didáctico V2-like. Abajo: mejoras reales, impacto esperado y coste.

### 5.1 Ya aplicado (baseline Fase 8)

Ver tabla completa en [`GAS-ES.md`](./GAS-ES.md). Resumen:

- Immutables, packing de reservas, custom errors, `unchecked` acotado, SafeTransfer, EIP-1153, cache de tokens, `_K_DENOMINATOR`.
- Snapshot e2e orientativo: swap ~280k gas (incluye transfers ERC-20), mint/burn en rango ~226k–273k.

### 5.2 Mejoras posibles (priorizadas)

| # | Idea | Impacto estimado | Riesgo / coste | ¿Vale la pena en v1? |
|---|------|------------------|----------------|----------------------|
| 1 | Subir `optimizer_runs` (p. ej. 1_000–10_000) | −runtime en hot path; ↑ bytecode / deploy | Hay que re-medir snapshot | Sí, fácil de probar |
| 2 | `via_ir = true` + quitar scope blocks en `swap` | Puede bajar gas y simplificar código | Compiles más lentos; verificar stack | Probar en rama |
| 3 | Assembly / Yul en K-check o UQ112 | Ahorro pequeño–medio en swap | Legibilidad ↓; más superficie de bug | Solo si se busca paridad V2 absoluta |
| 4 | Unificar lecturas `balanceOf` (menos llamadas externas) | Medio (cada `balanceOf` cuesta) | Cambiar orden CEI con cuidado | Revisar con gas-report |
| 5 | Permit (EIP-2612) en tokens demo + Router | Menos txs de approve en UX (no gas on-chain del Pair) | Fuera del core AMM | Mejor en UI/tokens |
| 6 | Librería externa `SafeTransfer` linkeada | ↓ tamaño de cada contrato | Deploy de lib + linking | Marginal |
| 7 | Transient storage para más flags / caches | Cancun-friendly | Complejidad | Bajo ROI ahora |
| 8 | Compactar eventos (menos indexed / datos) | Pequeño | Menos UX para indexers | No prioritario |
| 9 | Quitar TWAP si no se usa | −SSTORE en `_update` | Pierde feature del módulo | No (es objetivo del módulo) |
| 10 | Multi-hop Router | UX ↑ | Gas ↑ y loops | Fuera de alcance v1 |

### 5.3 Qué **no** conviene “optimizar” a ciegas

- **Sacar `nonReentrant`:** ahorrarías gas y abrirías SWC-107.
- **Volver a `require` strings:** empeora gas y DX.
- **Ampliar a `uint256` reservas “por claridad”:** rompe packing y sube SSTORE.
- **Fee-on-transfer / rebasing tokens:** cambiarían toda la contabilidad; fuera de v1 a propósito.

### 5.4 Cómo medir cualquier mejora

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test --match-contract TokenSwapGasTest --gas-report
forge snapshot --match-contract TokenSwapGasTest
# comparar con .gas-snapshot y actualizar doc/GAS-ES.md
```

Regla práctica: **no mergear** una “optimización” sin Δ de snapshot y sin que fuzz + invariantes + attack sigan en verde.

---

## 6. Mapa rápido código ↔ concepto

| Concepto | Dónde mirar |
|----------|-------------|
| Mint / swap / burn / TWAP | `src/TokenSwapPair.sol` |
| Crear par | `src/TokenSwapFactory.sol` |
| Slippage / deadline | `src/TokenSwapRouter.sol` |
| Transfers seguros | `src/libraries/SafeTransfer.sol` |
| Guard reentrancy | `src/utils/ReentrancyGuard.sol` |
| Baseline gas | `doc/GAS-ES.md`, `test/gas/`, `.gas-snapshot` |
| Matriz SWC | `doc/SWC-AUDIT-ES.md` |
| Demo UI | `frontend/` |
| Portfolio estático | `portfolio/index.html` |

---

## 7. Resumen ejecutivo

1. **Decisiones:** AMM V2-like, fee en K-check, Pair + Factory + Router, seguridad primero (CEI, guard, SafeTransfer), gas con packing/immutables/EIP-1153, UI aparte.
2. **Lógica:** depositar → mint LP; swap midiendo balances y verificando K; retirar quemando LP; Router solo orquesta y protege slippage.
3. **Gas:** ya hay baseline sólido; las mejoras más sanas son tunear optimizer/`via_ir` y reducir llamadas externas, siempre con snapshot. No sacrificar reentrancy ni el K-check por unos cientos de gas.

---

*Última actualización: alineado con Fases 0–8 + UI del módulo 06.*
