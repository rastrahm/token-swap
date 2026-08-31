# 06 — Constant Product AMM (Token Swap)

AMM de producto constante (`x * y = k`) con fee **0.3%**, mint/burn de LP y oráculo TWAP. Solidity `0.8.24` + Foundry.

**Estado:** Fases **0–1** ✅ (scaffold + tests TDD en rojo). Fases 2–8 y demo Next.js pendientes.

---

## Stack

| Capa | Tecnología |
|------|------------|
| Contratos | Solidity `0.8.24` |
| Tooling | Foundry (`forge` / `cast` / `anvil`) |
| Librerías | OpenZeppelin Contracts v5.2, forge-std |
| Modelo | Constant product · fee 997/1000 · TWAP |
| UI demo | Next.js 15 (fase UI) |

---

## Documentación

| Doc | Descripción |
|-----|-------------|
| [doc/README.md](./doc/README.md) | Índice de documentación |
| [doc/PLANIFICACION.md](./doc/PLANIFICACION.md) | Plan, fases TDD y criterios de aceptación |
| [doc/diagrama-flujo.md](./doc/diagrama-flujo.md) | Flujos mint / swap / burn |
| [doc/diagrama-clases.md](./doc/diagrama-clases.md) | UML de contratos |
| [doc/flujograma.md](./doc/flujograma.md) | Flujograma operativo y K-check |

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
src/mocks/           # MockERC20 (tests / Anvil)
src/utils/           # ReentrancyGuard (EIP-1153)
test/                # Phase0 smoke; unit/fuzz/invariant en fases 1+
doc/                 # Plan y diagramas
lib/                 # Dependencias (gitignored)
```

---

## Comandos útiles

```shell
forge build
forge test
forge test --fuzz-runs 1000
forge fmt
```
