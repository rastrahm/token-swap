# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fases 0–4** cerradas (scaffold, TDD, Math/TWAP, mint, swap+K).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Pair:** `mint` + `swap` (fee 0.3%, K-check, SafeERC20) + `_update`/`sync`  
**Pendiente:** burn/skim (fase 5)  
**Tests:** 27 PASS · 2 FAIL (burn en rojo TDD)
