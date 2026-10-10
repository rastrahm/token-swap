# Flujograma del proyecto — Constant Product AMM (Token Swap)

🇬🇧 [English version](./flujograma-EN.md)

Flujograma operativo **to-be** (v1): setup → liquidez → swap/K-check → TWAP → seguridad → UI.

## 1. Flujograma maestro del sistema

```mermaid
flowchart TB
    subgraph SETUP["FASE 0 — Setup"]
        S1[Inicializar Foundry 0.8.24] --> S2[Deploy TokenSwapFactory]
        S2 --> S3[createPair token0, token1]
        S3 --> S4[Deploy MockERC20 / tokens de prueba]
    end

    subgraph LIQ["FASE 1 — Liquidez"]
        L1[LP aprueba y envía token0+token1] --> L2{Validaciones mint}
        L2 -->|amounts 0| Lx1[InsufficientLiquidity]
        L2 -->|OK primer| L3[sqrt - MINIMUM_LIQUIDITY]
        L2 -->|OK later| L4[Pro-rata min amounts]
        L3 --> L5[_mint LP + _update]
        L4 --> L5
        L5 --> L6[Emit Mint / Sync]
    end

    subgraph BRANCH["FASE 2 — Uso del pool"]
        B1{¿Qué ocurre?}
        B1 -->|Swap| P1
        B1 -->|Burn| C1
        B1 -->|Skim/Sync| K1
    end

    subgraph SWAP["FASE 2a — Swap + K"]
        P1[Entrar nonReentrant] --> P2{outs válidos vs reservas?}
        P2 -->|No| Px[InsufficientOutput / Liquidity]
        P2 -->|Sí| P3[Transfer outs → to]
        P3 --> P4[Calcular amountIn]
        P4 --> P5[Ajuste fee *997 / *1000]
        P5 --> P6{K-check adjusted?}
        P6 -->|No| Py[InvalidK]
        P6 -->|Sí| P7[_update TWAP]
        P7 --> P8[Emit Swap]
        P8 --> P9[Salir nonReentrant]
    end

    subgraph BURN["FASE 2b — Retiro"]
        C1[LP envía LP al Pair] --> C2[Calcular pro-rata]
        C2 --> C3[_burn + transfer tokens]
        C3 --> C4[_update + Emit Burn]
    end

    subgraph MAINT["FASE 2c — Mantenimiento"]
        K1[skim o sync] --> K2[Alinear balance ↔ reservas]
    end

    SETUP --> LIQ
    LIQ --> BRANCH
    BRANCH --> SWAP
    BRANCH --> BURN
    BRANCH --> MAINT
    SWAP --> END1([Pool activo])
    BURN --> END1
    MAINT --> END1
```

## 2. Flujograma detallado del K-check (fee 0.3%)

```mermaid
flowchart TD
    Start([Post-transfer de outputs]) --> Bal[Leer balance0, balance1 del Pair]
    Bal --> In0[amount0In = balance0 > reserve0 ? diff : 0]
    In0 --> In1[amount1In = balance1 > reserve1 ? diff : 0]
    In1 --> Need{amount0In > 0 o amount1In > 0?}
    Need -->|No| FailIn[InsufficientInputAmount]
    Need -->|Sí| Adj0[bal0Adj = balance0 * 1000 - amount0In * 3]
    Adj0 --> Adj1[bal1Adj = balance1 * 1000 - amount1In * 3]
    Adj1 --> Cmp{bal0Adj * bal1Adj >=<br/>uint reserve0 * reserve1 * 1_000_000?}
    Cmp -->|No| FailK[InvalidK]
    Cmp -->|Sí| Ok([K válido — proceder _update])
```

## 3. Flujograma de seguridad (reentrancy)

```mermaid
flowchart TD
    A[Atacante llama mint/swap/burn] --> B[nonReentrant: status = ENTERED]
    B --> C[Checks + Effects de estado LP/reservas]
    C --> D[Interaction: transfer ERC-20]
    D --> E{Token/receiver malicioso<br/>reentra en callback?}
    E -->|Sí| F[Segunda llamada a mint/swap/burn]
    F --> G{status == ENTERED?}
    G -->|Sí| H[Revert ReentrancyGuard]
    G -->|No| I[No debería ocurrir]
    E -->|No| J[Continúa flujo normal]
    H --> K([Ataque fallido — estado consistente])
    J --> L([Transacción OK + _update])
```

## 4. Flujograma del pipeline de desarrollo (TDD)

```mermaid
flowchart LR
    A[.cursorrules] --> B[Docs planificación]
    B --> C[Tests .t.sol rojos]
    C --> D[Math.sqrt + Pair skeleton]
    D --> E[mint + MINIMUM_LIQUIDITY]
    E --> F[swap + fee + InvalidK]
    F --> G[burn + skim/sync]
    G --> H[Factory + Router]
    H --> I[Invariant + Fuzz 1000]
    I --> J[Gas + NatSpec + SafeERC20]
    J --> K[Demo Next.js]
    K --> L([Módulo cerrado])
```

## 5. Matriz flujo ↔ función ↔ invariante

| Paso del flujograma | Función | Invariante |
|---------------------|---------|------------|
| Crear par | `Factory.createPair` | `token0 < token1`; un solo pair |
| Primer mint | `mint` | `totalSupply = sqrt(a0*a1)`; 1000 LP locked |
| Mint posterior | `mint` | shares ∝ min pro-rata |
| Pre-swap | `swap` | outs ≤ reservas; al menos un out > 0 |
| Post-fee | `swap` | `balAdj0 * balAdj1 >= r0 * r1 * 1000²` |
| Post-swap | `_update` | `reserve0 * reserve1` refleja balances |
| TWAP | `_update` | cumulatives ↑ solo si `timeElapsed > 0` |
| Burn | `burn` | tokens out ∝ LP quemados |
| Invariant suite | Handler | `reserve0 * reserve1 >= k` a lo largo de la secuencia |
| Reentrada | guard | segunda llamada revierte |

## 6. Flujo UI (demo)

```mermaid
flowchart TD
    U1[Abrir localhost:3000] --> U2[Conectar wallet Anvil]
    U2 --> U3{Acción}
    U3 -->|Añadir liquidez| U4[approve + Router.addLiquidity]
    U3 -->|Swap| U5[approve + swapExactTokensForTokens]
    U3 -->|Retirar| U6[approve LP + removeLiquidity]
    U3 -->|Ver reservas / precio| U7[getReserves + quote]
    U4 --> U8[Actualizar UI]
    U5 --> U8
    U6 --> U8
    U7 --> U8
```

## 7. Cómo leer estos diagramas

1. **Setup → Liquidez**: el pool nace vacío; el primer mint fija el precio implícito.  
2. **Branch**: swap (con K-check), burn o mantenimiento.  
3. **K-check**: el fee 0.3% está embebido en el producto ajustado `*1000` / `*3`.  
4. **TWAP / fuzz / UI**: cierre del módulo (fases 0–8 + demo).
