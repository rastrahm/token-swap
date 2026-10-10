# Documentación — Module 06: Constant Product AMM

🇬🇧 [English version](./README-EN.md)

Índice de la carpeta `doc/`. **Proyecto completo** (contratos + seguridad + gas + UI).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION-ES.md](./PLANIFICACION-ES.md) | Objetivo, alcance, fases TDD, criterios |
| [DECISIONES-ES.md](./DECISIONES-ES.md) | Decisiones técnicas, lógica del sistema, mejoras de gas |
| [SWC-AUDIT-ES.md](./SWC-AUDIT-ES.md) | Matriz SWC-100–136, mapeo a tests |
| [GAS-ES.md](./GAS-ES.md) | Baseline gas, optimizaciones, snapshot |
| [DEPLOY-ES.md](./DEPLOY-ES.md) | Deploy Anvil + `.env.local` del frontend |
| [diagrama-clases-ES.md](./diagrama-clases-ES.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo-ES.md](./diagrama-flujo-ES.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma-ES.md](./flujograma-ES.md) | Operativo, K-check, seguridad, pipeline TDD |

**Contratos:** `TokenSwapPair` · `TokenSwapFactory` · `TokenSwapRouter`  
**UI:** `frontend/` — swap, liquidez, tema claro/oscuro  
**Tests:** `forge test` → **60 PASS** · `cd frontend && npm test`
