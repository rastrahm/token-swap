# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fases 0–8** cerradas (Pair + Factory + Router + seguridad + gas).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [SWC-AUDIT.md](./SWC-AUDIT.md) | Matriz SWC-100–136, mapeo a tests |
| [GAS.md](./GAS.md) | Baseline gas, optimizaciones, snapshot |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Contratos:** `TokenSwapPair` · `TokenSwapFactory` · `TokenSwapRouter`  
**Pendiente:** demo Next.js (UI)  
**Tests:** `forge test` → **60 PASS** · `forge snapshot`
