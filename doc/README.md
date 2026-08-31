# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Fases 0–2** cerradas (scaffold, TDD rojo mint/swap/burn, Math + TWAP).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Libs:** `src/libraries/Math.sol`, `UQ112x112.sol`  
**Pair:** `_update` + `sync` (TWAP) · mint/swap/burn stub  
**Tests:** Math 6 PASS · Update 4 PASS · Phase0 5 PASS · Pair 3 PASS / 11 FAIL (rojo TDD)
