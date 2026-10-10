# Flow diagram — Constant Product AMM (Token Swap)

🇪🇸 [Versión en español](./diagrama-flujo-ES.md)

**To-be** business flows (v1). See also [flujograma-EN.md](./flujograma-EN.md) and [PLANIFICACION-EN.md](./PLANIFICACION-EN.md).

## 1. Pair lifecycle

```mermaid
flowchart TD
    Start([Start]) --> DeployF[Deploy TokenSwapFactory]
    DeployF --> Create[createPair tokenA, tokenB]
    Create --> PairReady[Pair ready — reserves 0]

    PairReady --> LPAction{LP action}
    LPAction -->|transfer + mint| Mint[Add liquidity]
    LPAction -->|transfer LP + burn| Burn[Remove liquidity]

    PairReady --> TradeAction{Trader action}
    TradeAction -->|transfer in + swap| Swap[Swap tokens]

    Mint --> Active[Reserves > 0<br/>k = r0 * r1]
    Burn --> Active
    Swap --> Active
    Active -.->|still operable| PairReady
```

## 2. Mint flow (first deposit vs subsequent)

```mermaid
flowchart TD
    A([LP transfers token0/token1 to the Pair<br/>then calls mint to]) --> B[nonReentrant ON]
    B --> C[Read balances and reserves]
    C --> D[amount0 = balance0 - reserve0<br/>amount1 = balance1 - reserve1]
    D --> E{totalSupply == 0?}
    E -->|Yes — first mint| F[liquidity = sqrt amount0*amount1 - MINIMUM_LIQUIDITY]
    F --> G[Mint MINIMUM_LIQUIDITY → address 0]
    E -->|No| H[liquidity = min<br/>amount0*ts/r0 , amount1*ts/r1]
    G --> I{liquidity > 0?}
    H --> I
    I -->|No| E1[Revert InsufficientLiquidity]
    I -->|Yes| J[_mint LP → to]
    J --> K[_update balances → reserves + TWAP]
    K --> L[Emit Mint]
    L --> M[nonReentrant OFF]
    M --> N([LP receives shares])
```

## 3. Swap flow

```mermaid
flowchart TD
    A([Trader: input to the Pair<br/>calls swap amount0Out, amount1Out, to]) --> B{valid outs?}
    B -->|both 0| E1[InsufficientOutputAmount]
    B -->|out > reserve| E2[InsufficientLiquidity]
    B -->|OK| C[nonReentrant ON]
    C --> D[Transfer outs → to]
    D --> E[Measure amountIn from balance]
    E --> F{amountIn > 0?}
    F -->|No| E3[InsufficientInputAmount]
    F -->|Yes| G[balanceAdjusted =<br/>balance*1000 - amountIn*3]
    G --> H{bal0Adj * bal1Adj >=<br/>r0 * r1 * 1000² ?}
    H -->|No| E4[InvalidK]
    H -->|Yes| I[_update + TWAP]
    I --> J[Emit Swap + Sync]
    J --> K[nonReentrant OFF]
    K --> L([Swap OK])
```

## 4. Burn flow

```mermaid
flowchart TD
    A([LP transfers LP tokens to the Pair<br/>calls burn to]) --> B[nonReentrant ON]
    B --> C[liquidity = balanceOf pair]
    C --> D[amount0 = liq * balance0 / totalSupply<br/>amount1 = liq * balance1 / totalSupply]
    D --> E{amounts > 0?}
    E -->|No| E1[InsufficientLiquidity]
    E -->|Yes| F[_burn the Pair's LP]
    F --> G[_safeTransfer token0/1 → to]
    G --> H[_update reserves + TWAP]
    H --> I[Emit Burn]
    I --> J[nonReentrant OFF]
    J --> K([Tokens to the LP])
```

## 5. Router flow (slippage)

```mermaid
flowchart TD
    A([User calls Router]) --> B{Operation}
    B -->|addLiquidity| C[Compute optimal amounts]
    B -->|swapExactTokensForTokens| D[getAmountsOut]
    C --> E{amounts >= min?}
    E -->|No| Ex1[InsufficientA/BAmount]
    E -->|Yes| F[transferFrom → Pair + mint]
    D --> G{amountOut >= amountOutMin?}
    G -->|No| Ex2[InsufficientOutputAmount]
    G -->|Yes| H{deadline ok?}
    H -->|No| Ex3[Expired]
    H -->|Yes| I[transferFrom input → Pair + swap]
    F --> J([OK])
    I --> J
```

## 6. TWAP update (`_update`)

```mermaid
flowchart TD
    A[_update balance0, balance1, r0, r1] --> B[timeElapsed = timestamp - blockTimestampLast]
    B --> C{timeElapsed > 0<br/>and reserves > 0?}
    C -->|Yes| D[price0Cumulative +=<br/>UQ112 encode r1/r0 * dt]
    D --> E[price1Cumulative +=<br/>UQ112 encode r0/r1 * dt]
    C -->|No| F[Skip accumulation]
    E --> G[Write reserve0/1 + timestamp]
    F --> G
    G --> H[Emit Sync]
```

## Legend

| Symbol | Meaning |
|--------|---------|
| Rectangle | Process / action |
| Diamond | Decision / validation |
| Oval | Start / end |
| Dashed arrow | Persistent pair state |
