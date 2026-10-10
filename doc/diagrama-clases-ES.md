# Diagrama de clases — Constant Product AMM (Token Swap)

🇬🇧 [English version](./diagrama-clases-EN.md)

Modelo estructural **to-be** (módulo 06, planificación). Contratos, librerías, tests y demo UI.

## 1. Diagrama principal (UML / Mermaid)

```mermaid
classDiagram
    direction TB

    class IERC20 {
        <<interface>>
        +balanceOf(address) uint256
        +transfer(address, uint256) bool
        +transferFrom(address, address, uint256) bool
        +approve(address, uint256) bool
    }

    class Math {
        <<library>>
        +sqrt(uint256) uint256
        +min(uint256, uint256) uint256
    }

    class UQ112x112 {
        <<library>>
        +encode(uint112) uint224
        +uqdiv(uint224, uint112) uint224
    }

    class ITokenSwapPair {
        <<interface>>
        +getReserves() uint112, uint112, uint32
        +mint(address) uint256
        +burn(address) uint256, uint256
        +swap(uint256, uint256, address, bytes)
        +sync()
        +skim(address)
    }

    class ITokenSwapFactory {
        <<interface>>
        +createPair(address, address) address
        +getPair(address, address) address
        +allPairs(uint256) address
        +allPairsLength() uint256
    }

    class ITokenSwapRouter {
        <<interface>>
        +addLiquidity(...) uint256, uint256, uint256
        +removeLiquidity(...) uint256, uint256
        +swapExactTokensForTokens(...) uint256[]
        +getAmountsOut(uint256, address[]) uint256[]
    }

    class TokenSwapPair {
        +address factory
        +address token0
        +address token1
        +uint256 price0CumulativeLast
        +uint256 price1CumulativeLast
        +getReserves()
        +mint(address) uint256
        +burn(address) uint256, uint256
        +swap(uint256, uint256, address, bytes)
        +sync()
        +skim(address)
        -_update(uint256, uint256, uint112, uint112)
        -_safeTransfer(address, address, uint256)
    }

    class TokenSwapFactory {
        +mapping getPair
        +address[] allPairs
        +createPair(address, address) address
    }

    class TokenSwapRouter {
        +address factory
        +addLiquidity()
        +removeLiquidity()
        +swapExactTokensForTokens()
        +getAmountsOut()
    }

    class ReentrancyGuard {
        <<OZ / custom>>
        #nonReentrant()
    }

    class ERC20LP {
        <<OZ ERC20 — LP shares>>
        +totalSupply()
        +balanceOf()
        #_mint()
        #_burn()
    }

    ITokenSwapPair <|.. TokenSwapPair
    ReentrancyGuard <|-- TokenSwapPair
    ERC20LP <|-- TokenSwapPair
    ITokenSwapFactory <|.. TokenSwapFactory
    ITokenSwapRouter <|.. TokenSwapRouter
    TokenSwapPair ..> Math : mint liquidity
    TokenSwapPair ..> UQ112x112 : TWAP
    TokenSwapPair ..> IERC20 : reserves
    TokenSwapFactory ..> TokenSwapPair : create
    TokenSwapRouter ..> ITokenSwapFactory : resolve pair
    TokenSwapRouter ..> ITokenSwapPair : mint/burn/swap
```

## 2. Tests y handlers de invariantes

```mermaid
classDiagram
    direction LR

    class TokenSwapPair
    class TokenSwapFactory
    class MockERC20
    class TokenSwapPairTest
    class TokenSwapFactoryTest
    class TokenSwapRouterTest
    class TokenSwapFuzzTest
    class TokenSwapInvariantTest
    class Handler {
        <<invariant actor>>
        +mint()
        +burn()
        +swap()
        +sync()
    }

    MockERC20 ..|> IERC20
    TokenSwapPairTest --> TokenSwapPair
    TokenSwapPairTest --> MockERC20
    TokenSwapFactoryTest --> TokenSwapFactory
    TokenSwapRouterTest --> TokenSwapRouter
    TokenSwapFuzzTest --> TokenSwapPair
    TokenSwapInvariantTest --> Handler
    Handler --> TokenSwapPair
    Handler --> MockERC20
```

## 3. Frontend (demo)

```mermaid
classDiagram
    direction TB
    class SwapApp
    class SwapForm
    class LiquidityForm
    class AppToolbar
    class usePair
    class useWallet
    class useTheme
    class PublicEnv

    SwapApp --> AppToolbar
    SwapApp --> SwapForm
    SwapApp --> LiquidityForm
    SwapApp --> useWallet
    SwapForm --> usePair
    LiquidityForm --> usePair
    usePair ..> PublicEnv : Zod
    useWallet ..> PublicEnv
```

## 4. Responsabilidades

| Artefacto | Rol |
|-----------|-----|
| `TokenSwapPair` | Reservas, swap (0.3%), mint/burn LP, TWAP `_update`, K-check |
| `TokenSwapFactory` | Crear pares únicos; orden `token0 < token1` |
| `TokenSwapRouter` | Slippage, deadlines, transferFrom UX |
| `Math` | `sqrt` para liquidez geométrica |
| `UQ112x112` | Precio fixed-point para acumuladores TWAP |
| `ReentrancyGuard` | Lock en mint/swap/burn |
| `MockERC20` | Tokens de prueba Foundry / Anvil |
| `Handler` | Actor aleatorio para invariant testing |
| `SwapApp` | UI: swap + add/remove liquidity |

## 5. Dependencias (resumen)

```
TokenSwapPair
  ├── hereda     → ERC20 (LP), ReentrancyGuard
  ├── implementa → ITokenSwapPair
  ├── usa        → Math.sqrt, UQ112x112 (TWAP)
  ├── custodia   → IERC20 token0/token1
  ├── emite      → Mint / Burn / Swap / Sync
  └── revierte   → Insufficient* / InvalidK / ZeroAddress

TokenSwapFactory
  ├── createPair → new TokenSwapPair (o CREATE2)
  └── getPair    → mapping bidireccional

TokenSwapRouter
  ├── factory    → resolve pair
  └── pair       → mint / burn / swap con minOut
```

## 6. Layout Solidity (Pair)

1. Imports / interfaces / libraries  
2. Contract `TokenSwapPair`  
3. Immutables (`factory`, `token0`, `token1`)  
4. Packed reserves + TWAP state  
5. Events → Errors → Modifiers  
6. External: `getReserves`, `mint`, `burn`, `swap`, `skim`, `sync`  
7. Internal: `_update`, `_safeTransfer`
