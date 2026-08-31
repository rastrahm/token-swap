# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fases 0–3** cerradas (scaffold, TDD, Math/TWAP, mint).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Pair:** `mint` + `_update`/`sync` · LP via `TokenSwapERC20` (lock `MINIMUM_LIQUIDITY` → `address(0)`)  
**Pendiente:** swap (fase 4), burn/skim (fase 5)  
**Tests:** 21 PASS · 8 FAIL (swap/burn en rojo TDD)
