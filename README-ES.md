# 06 — Constant Product AMM (Token Swap)

🇬🇧 [English version](./README-EN.md)

AMM de producto constante (`x * y = k`) con fee **0.3%**, mint/burn de LP y oráculo TWAP. Solidity `0.8.24` + Foundry.

**Estado:** Fases **0–8** ✅ + **UI** ✅ (Next.js swap/LP + tema claro/oscuro).

---

## Stack

| Capa | Tecnología |
|------|------------|
| Contratos | Solidity `0.8.24` |
| Tooling | Foundry (`forge` / `cast` / `anvil`) |
| Librerías | OpenZeppelin Contracts v5.2, forge-std |
| Modelo | Constant product · fee 997/1000 · TWAP |
| UI demo | Next.js 15 (fase UI) — swap, liquidez, tema claro/oscuro |

---

## Documentación

| Doc | Descripción |
|-----|-------------|
| [doc/README-ES.md](./doc/README-ES.md) | Índice de documentación |
| [doc/PLANIFICACION-ES.md](./doc/PLANIFICACION-ES.md) | Plan, fases TDD y criterios de aceptación |
| [doc/DECISIONES-ES.md](./doc/DECISIONES-ES.md) | Decisiones técnicas, lógica del sistema y mejoras de gas |
| [doc/diagrama-flujo-ES.md](./doc/diagrama-flujo-ES.md) | Flujos mint / swap / burn |
| [doc/diagrama-clases-ES.md](./doc/diagrama-clases-ES.md) | UML de contratos |
| [doc/flujograma-ES.md](./doc/flujograma-ES.md) | Flujograma operativo y K-check |
| [doc/SWC-AUDIT-ES.md](./doc/SWC-AUDIT-ES.md) | Auditoría SWC-100–136 y mapeo a tests |
| [doc/GAS-ES.md](./doc/GAS-ES.md) | Gas report baseline y optimizaciones |
| [doc/DEPLOY-ES.md](./doc/DEPLOY-ES.md) | Deploy Anvil + configuración frontend |

---

## Setup

```shell
# Usar Foundry real (no el paquete npm "forge")
export PATH="$HOME/.foundry/bin:$PATH"

forge install foundry-rs/forge-std@v1.16.2 --no-git
forge install OpenZeppelin/openzeppelin-contracts@v5.2.0 --no-git

forge build
forge test
```

---

## Estructura

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
frontend/                    # Next.js demo (swap + LP + tema)
script/Deploy.s.sol          # Deploy Anvil para la UI
portfolio/                   # Página estática de portafolio (ES/EN)
doc/                 # Plan y diagramas
lib/                 # Dependencias (gitignored)
```

---

## Comandos útiles

```shell
forge build
forge test
cd frontend && npm install && npm run dev
forge fmt
```
