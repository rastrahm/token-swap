# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fases 0–1** cerradas (scaffold + tests TDD mint/swap/burn/K en rojo).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Interfaces:** `src/interfaces/ITokenSwap{Pair,Factory,Router}.sol`  
**Stub:** `src/TokenSwapPair.sol` (lógica en fases 2–5)  
**Tests:** `forge test` → Phase0 5 PASS · TokenSwapPair 3 PASS / 11 FAIL (rojo TDD)
