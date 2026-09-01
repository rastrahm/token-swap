# Documentación — Module 06: Constant Product AMM

Índice de la carpeta `doc/`. **Proyecto completo** (contratos + seguridad + gas + UI).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [SWC-AUDIT.md](./SWC-AUDIT.md) | Matriz SWC-100–136, mapeo a tests |
| [GAS.md](./GAS.md) | Baseline gas, optimizaciones, snapshot |
| [DEPLOY.md](./DEPLOY.md) | Deploy Anvil + `.env.local` del frontend |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests / UI |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos mint / swap / burn / Router / TWAP |
| [flujograma.md](./flujograma.md) | Operativo, K-check, seguridad, pipeline TDD |

**Contratos:** `TokenSwapPair` · `TokenSwapFactory` · `TokenSwapRouter`  
**UI:** `frontend/` — swap, liquidez, tema claro/oscuro  
**Tests:** `forge test` → **60 PASS** · `cd frontend && npm test`
