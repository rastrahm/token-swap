# Documentation — Module 06: Constant Product AMM

🇪🇸 [Versión en español](./README-ES.md)

Index of the `doc/` folder. **Project complete** (contracts + security + gas + UI).

| Document | Content |
|----------|---------|
| [PLANIFICACION-EN.md](./PLANIFICACION-EN.md) | Goal, scope, TDD phases, criteria |
| [DECISIONES-EN.md](./DECISIONES-EN.md) | Technical decisions, system logic, gas improvements |
| [SWC-AUDIT-EN.md](./SWC-AUDIT-EN.md) | SWC-100–136 matrix, test mapping |
| [GAS-EN.md](./GAS-EN.md) | Gas baseline, optimizations, snapshot |
| [DEPLOY-EN.md](./DEPLOY-EN.md) | Anvil deploy + frontend `.env.local` |
| [diagrama-clases-EN.md](./diagrama-clases-EN.md) | Contract / library / test / UI UML |
| [diagrama-flujo-EN.md](./diagrama-flujo-EN.md) | Mint / swap / burn / Router / TWAP flows |
| [flujograma-EN.md](./flujograma-EN.md) | Operations, K-check, security, TDD pipeline |

**Contracts:** `TokenSwapPair` · `TokenSwapFactory` · `TokenSwapRouter`  
**UI:** `frontend/` — swap, liquidity, light/dark theme  
**Tests:** `forge test` → **60 PASS** · `cd frontend && npm test`
