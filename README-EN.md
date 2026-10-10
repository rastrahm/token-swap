# 06 — Constant Product AMM (Token Swap)

🇪🇸 [Versión en español](./README-ES.md)

Constant product AMM (`x * y = k`) with a **0.3%** fee, LP mint/burn and a TWAP oracle. Solidity `0.8.24` + Foundry.

**Status:** Phases **0–8** ✅ + **UI** ✅ (Next.js swap/LP + light/dark theme).

---

## Stack

| Layer | Technology |
|-------|------------|
| Contracts | Solidity `0.8.24` |
| Tooling | Foundry (`forge` / `cast` / `anvil`) |
| Libraries | OpenZeppelin Contracts v5.2, forge-std |
| Model | Constant product · fee 997/1000 · TWAP |
| Demo UI | Next.js 15 (UI phase) — swap, liquidity, light/dark theme |

---

## Documentation

| Doc | Description |
|-----|-------------|
| [doc/README-EN.md](./doc/README-EN.md) | Documentation index |
| [doc/PLANIFICACION-EN.md](./doc/PLANIFICACION-EN.md) | Plan, TDD phases and acceptance criteria |
| [doc/DECISIONES-EN.md](./doc/DECISIONES-EN.md) | Technical decisions, system logic and gas improvements |
| [doc/diagrama-flujo-EN.md](./doc/diagrama-flujo-EN.md) | Mint / swap / burn flows |
| [doc/diagrama-clases-EN.md](./doc/diagrama-clases-EN.md) | Contract UML |
| [doc/flujograma-EN.md](./doc/flujograma-EN.md) | Operational flowchart and K-check |
| [doc/SWC-AUDIT-EN.md](./doc/SWC-AUDIT-EN.md) | SWC-100–136 audit and test mapping |
| [doc/GAS-EN.md](./doc/GAS-EN.md) | Gas report baseline and optimizations |
| [doc/DEPLOY-EN.md](./doc/DEPLOY-EN.md) | Anvil deploy + frontend configuration |

---

## Setup

```shell
# Use the real Foundry (not the npm "forge" package)
export PATH="$HOME/.foundry/bin:$PATH"

forge install foundry-rs/forge-std@v1.16.2 --no-git
forge install OpenZeppelin/openzeppelin-contracts@v5.2.0 --no-git

forge build
forge test
```

---

## Structure

```
src/interfaces/      # ITokenSwapPair, Factory, Router
src/libraries/       # Math.sqrt, UQ112x112 (TWAP), SafeTransfer
src/mocks/           # MockERC20 (tests / Anvil)
src/utils/           # ReentrancyGuard (EIP-1153)
src/TokenSwapFactory.sol
src/TokenSwapRouter.sol      # add/remove liquidity + swap (slippage)
src/TokenSwapERC20.sol
src/TokenSwapPair.sol
test/                        # Pair, Factory, Router, fuzz, invariant, attack, gas
frontend/                    # Next.js demo (swap + LP + theme)
script/Deploy.s.sol          # Anvil deploy for the UI
portfolio/                   # Static portfolio page (ES/EN)
doc/                 # Plan and diagrams
lib/                 # Dependencies (gitignored)
```

---

## Useful commands

```shell
forge build
forge test
cd frontend && npm install && npm run dev
forge fmt
```
