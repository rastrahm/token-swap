# Diagrama de flujo — Constant Product AMM (Token Swap)

🇬🇧 [English version](./diagrama-flujo-EN.md)

Flujos de negocio **to-be** (v1). Ver también [flujograma-ES.md](./flujograma-ES.md) y [PLANIFICACION-ES.md](./PLANIFICACION-ES.md).

## 1. Ciclo de vida del par

```mermaid
flowchart TD
    Start([Inicio]) --> DeployF[Deploy TokenSwapFactory]
    DeployF --> Create[createPair tokenA, tokenB]
    Create --> PairReady[Pair listo — reservas 0]

    PairReady --> LPAction{Acción LP}
    LPAction -->|transfer + mint| Mint[Añadir liquidez]
    LPAction -->|transfer LP + burn| Burn[Retirar liquidez]

    PairReady --> TradeAction{Acción Trader}
    TradeAction -->|transfer in + swap| Swap[Intercambiar tokens]

    Mint --> Active[Reservas > 0<br/>k = r0 * r1]
    Burn --> Active
    Swap --> Active
    Active -.->|sigue operable| PairReady
```

## 2. Flujo de mint (primer depósito vs subsequent)

```mermaid
flowchart TD
    A([LP transfiere token0/token1 al Pair<br/>luego llama mint to]) --> B[nonReentrant ON]
    B --> C[Leer balances y reservas]
    C --> D[amount0 = balance0 - reserve0<br/>amount1 = balance1 - reserve1]
    D --> E{totalSupply == 0?}
    E -->|Sí — primer mint| F[liquidity = sqrt amount0*amount1 - MINIMUM_LIQUIDITY]
    F --> G[Mint MINIMUM_LIQUIDITY → address 0]
    E -->|No| H[liquidity = min<br/>amount0*ts/r0 , amount1*ts/r1]
    G --> I{liquidity > 0?}
    H --> I
    I -->|No| E1[Revert InsufficientLiquidity]
    I -->|Sí| J[_mint LP → to]
    J --> K[_update balances → reservas + TWAP]
    K --> L[Emit Mint]
    L --> M[nonReentrant OFF]
    M --> N([LP recibe shares])
```

## 3. Flujo de swap

```mermaid
flowchart TD
    A([Trader: input al Pair<br/>llama swap amount0Out, amount1Out, to]) --> B{outs válidos?}
    B -->|ambos 0| E1[InsufficientOutputAmount]
    B -->|out > reserve| E2[InsufficientLiquidity]
    B -->|OK| C[nonReentrant ON]
    C --> D[Transfer outs → to]
    D --> E[Medir amountIn por balance]
    E --> F{amountIn > 0?}
    F -->|No| E3[InsufficientInputAmount]
    F -->|Sí| G[balanceAdjusted =<br/>balance*1000 - amountIn*3]
    G --> H{bal0Adj * bal1Adj >=<br/>r0 * r1 * 1000² ?}
    H -->|No| E4[InvalidK]
    H -->|Sí| I[_update + TWAP]
    I --> J[Emit Swap + Sync]
    J --> K[nonReentrant OFF]
    K --> L([Swap OK])
```

## 4. Flujo de burn

```mermaid
flowchart TD
    A([LP transfiere LP tokens al Pair<br/>llama burn to]) --> B[nonReentrant ON]
    B --> C[liquidity = balanceOf pair]
    C --> D[amount0 = liq * balance0 / totalSupply<br/>amount1 = liq * balance1 / totalSupply]
    D --> E{amounts > 0?}
    E -->|No| E1[InsufficientLiquidity]
    E -->|Sí| F[_burn LP del Pair]
    F --> G[_safeTransfer token0/1 → to]
    G --> H[_update reservas + TWAP]
    H --> I[Emit Burn]
    I --> J[nonReentrant OFF]
    J --> K([Tokens al LP])
```

## 5. Flujo Router (slippage)

```mermaid
flowchart TD
    A([Usuario llama Router]) --> B{Operación}
    B -->|addLiquidity| C[Calcular optimal amounts]
    B -->|swapExactTokensForTokens| D[getAmountsOut]
    C --> E{amounts >= min?}
    E -->|No| Ex1[InsufficientA/BAmount]
    E -->|Sí| F[transferFrom → Pair + mint]
    D --> G{amountOut >= amountOutMin?}
    G -->|No| Ex2[InsufficientOutputAmount]
    G -->|Sí| H{deadline ok?}
    H -->|No| Ex3[Expired]
    H -->|Sí| I[transferFrom input → Pair + swap]
    F --> J([OK])
    I --> J
```

## 6. Actualización TWAP (`_update`)

```mermaid
flowchart TD
    A[_update balance0, balance1, r0, r1] --> B[timeElapsed = timestamp - blockTimestampLast]
    B --> C{timeElapsed > 0<br/>y reservas > 0?}
    C -->|Sí| D[price0Cumulative +=<br/>UQ112 encode r1/r0 * dt]
    D --> E[price1Cumulative +=<br/>UQ112 encode r0/r1 * dt]
    C -->|No| F[Saltar acumulación]
    E --> G[Escribir reserve0/1 + timestamp]
    F --> G
    G --> H[Emit Sync]
```

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| Rectángulo | Proceso / acción |
| Diamante | Decisión / validación |
| Óvalo | Inicio / fin |
| Flecha punteada | Estado persistente del par |
