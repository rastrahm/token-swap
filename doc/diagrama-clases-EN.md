# Class diagram — Constant Product AMM (Token Swap)

🇪🇸 [Versión en español](./diagrama-clases-ES.md)

**To-be** structural model (module 06, planning). Contracts, libraries, tests and demo UI.

## 1. Main diagram (UML / Mermaid)

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

## 2. Tests and invariant handlers

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

## 4. Responsibilities

| Artifact | Role |
|----------|------|
| `TokenSwapPair` | Reserves, swap (0.3%), LP mint/burn, TWAP `_update`, K-check |
| `TokenSwapFactory` | Create unique pairs; order `token0 < token1` |
| `TokenSwapRouter` | Slippage, deadlines, transferFrom UX |
| `Math` | `sqrt` for geometric liquidity |
| `UQ112x112` | Fixed-point price for TWAP accumulators |
| `ReentrancyGuard` | Lock on mint/swap/burn |
| `MockERC20` | Test tokens for Foundry / Anvil |
| `Handler` | Random actor for invariant testing |
| `SwapApp` | UI: swap + add/remove liquidity |

## 5. Dependencies (summary)

```
TokenSwapPair
  ├── inherits   → ERC20 (LP), ReentrancyGuard
  ├── implements → ITokenSwapPair
  ├── uses       → Math.sqrt, UQ112x112 (TWAP)
  ├── holds      → IERC20 token0/token1
  ├── emits      → Mint / Burn / Swap / Sync
  └── reverts    → Insufficient* / InvalidK / ZeroAddress

TokenSwapFactory
  ├── createPair → new TokenSwapPair (or CREATE2)
  └── getPair    → bidirectional mapping

TokenSwapRouter
  ├── factory    → resolve pair
  └── pair       → mint / burn / swap with minOut
```

## 6. Solidity layout (Pair)

1. Imports / interfaces / libraries  
2. Contract `TokenSwapPair`  
3. Immutables (`factory`, `token0`, `token1`)  
4. Packed reserves + TWAP state  
5. Events → Errors → Modifiers  
6. External: `getReserves`, `mint`, `burn`, `swap`, `skim`, `sync`  
7. Internal: `_update`, `_safeTransfer`
