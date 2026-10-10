# Deploy local — Token Swap AMM

🇬🇧 [English version](./DEPLOY-EN.md)

## Requisitos

- Anvil en `http://127.0.0.1:8545`
- Foundry (`forge`)

## Deploy

```bash
export PATH="$HOME/.foundry/bin:$PATH"
anvil   # terminal 1

forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Copiá del log:

| Variable | Log |
|----------|-----|
| `NEXT_PUBLIC_TOKEN_A_ADDRESS` | `TokenA` |
| `NEXT_PUBLIC_TOKEN_B_ADDRESS` | `TokenB` |
| `NEXT_PUBLIC_FACTORY_ADDRESS` | `Factory` |
| `NEXT_PUBLIC_ROUTER_ADDRESS` | `Router` |
| `NEXT_PUBLIC_PAIR_ADDRESS` | `Pair` |

En `frontend/.env.local`:

```env
NEXT_PUBLIC_RPC_URL=http://127.0.0.1:8545
NEXT_PUBLIC_CHAIN_ID=31337
```

## Frontend

Requiere **Node ≥ 20.19** (`frontend/.nvmrc`).

```bash
cd frontend
cp .env.example .env.local
# editar addresses
npm install
npm test
npm run dev          # webpack (estable)
# npm run dev:turbo  # más rápido, pero puede corromper .next en sesiones largas
# npm run dev:clean  # si ves error 500 / ENOENT en .next
```

Abrir `http://localhost:3000` y conectar MetaMask (cuenta Anvil #0, red 31337).

Manual de uso en la app: `/ayuda` o botón **? Ayuda** en la barra superior.
