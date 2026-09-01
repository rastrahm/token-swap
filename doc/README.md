# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fases 0–6** cerradas (Pair + Factory + Router).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Contratos:** `TokenSwapPair` · `TokenSwapFactory` · `TokenSwapRouter`  
**Pendiente:** invariant/fuzz (fase 7), gas/NatSpec (fase 8)  
**Tests:** `forge test` → **41 PASS**
