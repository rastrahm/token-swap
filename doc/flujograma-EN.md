# Project flowchart — Constant Product AMM (Token Swap)

🇪🇸 [Versión en español](./flujograma-ES.md)

**To-be** operational flowchart (v1): setup → liquidity → swap/K-check → TWAP → security → UI.

## 1. Master system flowchart

```mermaid
flowchart TB
    subgraph SETUP["PHASE 0 — Setup"]
        S1[Initialize Foundry 0.8.24] --> S2[Deploy TokenSwapFactory]
        S2 --> S3[createPair token0, token1]
        S3 --> S4[Deploy MockERC20 / test tokens]
    end

    subgraph LIQ["PHASE 1 — Liquidity"]
        L1[LP approves and sends token0+token1] --> L2{Mint validations}
        L2 -->|amounts 0| Lx1[InsufficientLiquidity]
        L2 -->|OK first| L3[sqrt - MINIMUM_LIQUIDITY]
        L2 -->|OK later| L4[Pro-rata min amounts]
        L3 --> L5[_mint LP + _update]
        L4 --> L5
        L5 --> L6[Emit Mint / Sync]
    end

    subgraph BRANCH["PHASE 2 — Pool usage"]
        B1{What happens?}
        B1 -->|Swap| P1
        B1 -->|Burn| C1
        B1 -->|Skim/Sync| K1
    end

    subgraph SWAP["PHASE 2a — Swap + K"]
        P1[Enter nonReentrant] --> P2{valid outs vs reserves?}
        P2 -->|No| Px[InsufficientOutput / Liquidity]
        P2 -->|Yes| P3[Transfer outs → to]
        P3 --> P4[Compute amountIn]
        P4 --> P5[Fee adjustment *997 / *1000]
        P5 --> P6{Adjusted K-check?}
        P6 -->|No| Py[InvalidK]
        P6 -->|Yes| P7[_update TWAP]
        P7 --> P8[Emit Swap]
        P8 --> P9[Exit nonReentrant]
    end

    subgraph BURN["PHASE 2b — Withdrawal"]
        C1[LP sends LP to the Pair] --> C2[Compute pro-rata]
        C2 --> C3[_burn + transfer tokens]
        C3 --> C4[_update + Emit Burn]
    end

    subgraph MAINT["PHASE 2c — Maintenance"]
        K1[skim or sync] --> K2[Align balance ↔ reserves]
    end

    SETUP --> LIQ
    LIQ --> BRANCH
    BRANCH --> SWAP
    BRANCH --> BURN
    BRANCH --> MAINT
    SWAP --> END1([Active pool])
    BURN --> END1
    MAINT --> END1
```

## 2. Detailed K-check flowchart (0.3% fee)

```mermaid
flowchart TD
    Start([After output transfer]) --> Bal[Read the Pair's balance0, balance1]
    Bal --> In0[amount0In = balance0 > reserve0 ? diff : 0]
    In0 --> In1[amount1In = balance1 > reserve1 ? diff : 0]
    In1 --> Need{amount0In > 0 or amount1In > 0?}
    Need -->|No| FailIn[InsufficientInputAmount]
    Need -->|Yes| Adj0[bal0Adj = balance0 * 1000 - amount0In * 3]
    Adj0 --> Adj1[bal1Adj = balance1 * 1000 - amount1In * 3]
    Adj1 --> Cmp{bal0Adj * bal1Adj >=<br/>uint reserve0 * reserve1 * 1_000_000?}
    Cmp -->|No| FailK[InvalidK]
    Cmp -->|Yes| Ok([Valid K — proceed to _update])
```

## 3. Security flowchart (reentrancy)

```mermaid
flowchart TD
    A[Attacker calls mint/swap/burn] --> B[nonReentrant: status = ENTERED]
    B --> C[Checks + LP/reserve state Effects]
    C --> D[Interaction: ERC-20 transfer]
    D --> E{Malicious token/receiver<br/>reenters via callback?}
    E -->|Yes| F[Second call to mint/swap/burn]
    F --> G{status == ENTERED?}
    G -->|Yes| H[Revert ReentrancyGuard]
    G -->|No| I[Should never happen]
    E -->|No| J[Normal flow continues]
    H --> K([Attack failed — consistent state])
    J --> L([Transaction OK + _update])
```

## 4. Development pipeline flowchart (TDD)

```mermaid
flowchart LR
    A[.cursorrules] --> B[Planning docs]
    B --> C[Red .t.sol tests]
    C --> D[Math.sqrt + Pair skeleton]
    D --> E[mint + MINIMUM_LIQUIDITY]
    E --> F[swap + fee + InvalidK]
    F --> G[burn + skim/sync]
    G --> H[Factory + Router]
    H --> I[Invariant + Fuzz 1000]
    I --> J[Gas + NatSpec + SafeERC20]
    J --> K[Next.js demo]
    K --> L([Module closed])
```

## 5. Flow ↔ function ↔ invariant matrix

| Flowchart step | Function | Invariant |
|----------------|----------|-----------|
| Create pair | `Factory.createPair` | `token0 < token1`; a single pair |
| First mint | `mint` | `totalSupply = sqrt(a0*a1)`; 1000 LP locked |
| Subsequent mint | `mint` | shares ∝ pro-rata min |
| Pre-swap | `swap` | outs ≤ reserves; at least one out > 0 |
| Post-fee | `swap` | `balAdj0 * balAdj1 >= r0 * r1 * 1000²` |
| Post-swap | `_update` | `reserve0 * reserve1` reflects balances |
| TWAP | `_update` | cumulatives ↑ only if `timeElapsed > 0` |
| Burn | `burn` | tokens out ∝ LP burned |
| Invariant suite | Handler | `reserve0 * reserve1 >= k` throughout the sequence |
| Reentry | guard | second call reverts |

## 6. UI flow (demo)

```mermaid
flowchart TD
    U1[Open localhost:3000] --> U2[Connect Anvil wallet]
    U2 --> U3{Action}
    U3 -->|Add liquidity| U4[approve + Router.addLiquidity]
    U3 -->|Swap| U5[approve + swapExactTokensForTokens]
    U3 -->|Remove| U6[approve LP + removeLiquidity]
    U3 -->|View reserves / price| U7[getReserves + quote]
    U4 --> U8[Refresh UI]
    U5 --> U8
    U6 --> U8
    U7 --> U8
```

## 7. How to read these diagrams

1. **Setup → Liquidity**: the pool starts empty; the first mint sets the implicit price.  
2. **Branch**: swap (with K-check), burn or maintenance.  
3. **K-check**: the 0.3% fee is embedded in the adjusted product `*1000` / `*3`.  
4. **TWAP / fuzz / UI**: module wrap-up (phases 0–8 + demo).
