# Local deploy — Token Swap AMM

🇪🇸 [Versión en español](./DEPLOY-ES.md)

## Requirements

- Anvil at `http://127.0.0.1:8545`
- Foundry (`forge`)

## Deploy

```bash
export PATH="$HOME/.foundry/bin:$PATH"
anvil   # terminal 1

forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Copy from the log:

| Variable | Log |
|----------|-----|
| `NEXT_PUBLIC_TOKEN_A_ADDRESS` | `TokenA` |
| `NEXT_PUBLIC_TOKEN_B_ADDRESS` | `TokenB` |
| `NEXT_PUBLIC_FACTORY_ADDRESS` | `Factory` |
| `NEXT_PUBLIC_ROUTER_ADDRESS` | `Router` |
| `NEXT_PUBLIC_PAIR_ADDRESS` | `Pair` |

In `frontend/.env.local`:

```env
NEXT_PUBLIC_RPC_URL=http://127.0.0.1:8545
NEXT_PUBLIC_CHAIN_ID=31337
```

## Frontend

Requires **Node ≥ 20.19** (`frontend/.nvmrc`).

```bash
cd frontend
cp .env.example .env.local
# edit addresses
npm install
npm test
npm run dev          # webpack (stable)
# npm run dev:turbo  # faster, but may corrupt .next in long sessions
# npm run dev:clean  # if you see a 500 error / ENOENT in .next
```

Open `http://localhost:3000` and connect MetaMask (Anvil account #0, network 31337).

In-app user manual: `/ayuda` or the **? Ayuda** button in the top bar.
