# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fases 0–7** cerradas (Pair + Factory + Router + invariant/fuzz/SWC).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [SWC-AUDIT.md](./SWC-AUDIT.md) | Matriz SWC-100–136, mapeo a tests |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Contratos:** `TokenSwapPair` · `TokenSwapFactory` · `TokenSwapRouter`  
**Pendiente:** gas/NatSpec (fase 8), demo Next.js  
**Tests:** `forge test` (unit + fuzz + invariant + attack)
