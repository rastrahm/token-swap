# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fase 0** cerrada (scaffold Foundry + interfaces).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Interfaces:** `src/interfaces/ITokenSwap{Pair,Factory,Router}.sol`  
**Infra:** `src/mocks/MockERC20.sol`, `src/utils/ReentrancyGuard.sol`  
**Tests:** `forge test` → 5 smoke (`test/Phase0.t.sol`)
