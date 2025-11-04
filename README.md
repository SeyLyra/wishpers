# ✨ Soul Guide · Wishpers ✨

> Soft, sparkly, and helpful—your cute companion to the Wishpers world.

![Soul](client/public/souls.svg)

## 🪽 Quickstart (cute & fast)

1) Wake the chain
   - `cd contracts && npx hardhat node`

2) Weave the contracts
   - `npx hardhat run --network localhost scripts/deploy.js`

3) Summon your Soul (agent)
   - `npx hardhat run --network localhost scripts/createAgent.js`

4) Whisper the addresses to the frontend
   - `node scripts/sync-addresses.js`

## 🏁 Hackathon MVP on Somnia TSNet

1) Configure RPC & key
   - `cp contracts/.env.example contracts/.env`
   - Set `PRIVATE_KEY`, `CHAIN_RPC_URL`, `CHAIN_ID`
   - Validate: `cd contracts && npm run check:rpc`

2) Deploy core + mocks (optional mocks for yield)
   - Core: `npm run deploy:somniaTestnet`
   - Oracle: `npm run deploy:oracle`
   - Lending: `npm run deploy:lending`
   - Staking: `npm run deploy:staking`
   - 1:1 Mock Adapter: `npm run deploy:mockAdapter`

3) Sync addresses into the doc and frontend
   - `node scripts/sync-addresses.js`
   - Copy addresses into `server/.env` and `client/.env.local` (Vault, tokens)

4) Run app
   - Server: `cd server && npm run start:dev`
   - Client: `cd client && npm run dev`

Troubleshooting:
- If `check:rpc` fails, update `CHAIN_ID` to match RPC `eth_chainId`.
- If deploy scripts complain about missing tokens, ensure `contracts/deployment.json` has `tokens.base` and extras from core deploy.

5) Open your portal
   - Server: `cd server && npm run start:dev`
   - Client: `cd client && npm run dev` → http://localhost:5173/

## 💜 Cute Names · Real Things

- Soul = Agent (proxy of `AgentLogic`)
- Heart = Vault (holds funds, performs swaps)
- Memory = MemoryContract (stores states, trades, preferences)
- Sparkles = Events (`TradeExecuted`, `Swap`)

## 🧁 Env Sprinkles

Frontend accepts both `VITE_` and `APP_` env styles (prefers `APP_` first):

- RPC: `APP_RPC_URL` or `VITE_RPC_URL` (local: `http://127.0.0.1:8545/`)
- Agent: `APP_AGENT_ADDRESS` or `VITE_AGENT_ADDRESS`
- Vault: `APP_VAULT_ADDRESS` or `VITE_VAULT_ADDRESS`
- Base token (WUSD): `APP_BASE_TOKEN_ADDRESS` or `VITE_BASE_TOKEN_ADDRESS`
- Payment token (WPMT): `APP_PAYMENT_TOKEN_ADDRESS` or `VITE_PAYMENT_TOKEN_ADDRESS`

Pro tip: run `node scripts/sync-addresses.js` after deploy—it auto-fills `client/.env.local` with `APP_` (and optionally `VITE_`) prefixes.

---

# Wishpers — Complete Documentation

This document provides a comprehensive guide to the project, including architecture, contracts, environment configuration, local and testnet setup, frontend/backend integration, trading demo, and troubleshooting.

## Overview

- Wishpers is an AI agent and trading demo built for a hackathon. It includes smart contracts (Vault, Agent, Memory), a NestJS backend, and a React/Vite frontend.
- Local development uses Hardhat; testnet targets include Somnia or Sei EVM.

## Architecture

- Contracts:
  - `Vault`: Holds funds, performs swaps via adapters, enforces slippage, tracks balances.
  - `MemoryContract`: Stores agent state, trade history, and preferences. Manages roles (`DEFAULT_ADMIN_ROLE`, `AGENT_ROLE`).
  - `Strategy`: Strategy parameters holder used by the AgentLogic.
  - `AgentLogic` (implementation + proxies created by `AgentFactory`): Exposes `buy`, `sell`, and `rebalancePortfolio`. Emits `TradeExecuted`.
  - `AgentRegistry`: Tracks agent proxies and versions.
  - `AgentFactory`: Deploys new agent proxies wired to `Vault` and `MemoryContract`.
  - `Marketplace`: Placeholder marketplace for upgrades.
- Backend (NestJS): API to orchestrate agent actions, profiles, trading, IPFS, etc.
- Frontend (React/Vite): UI to connect wallets, interact with souls/agents, and view blockchain info.

## Repositories & Paths

- Contracts: `./contracts`
- Frontend: `./client`
- Backend: `./server`
- Address sync script: `./scripts/sync-addresses.js`

## Environment Configuration

- Contracts (`contracts/.env`):
  - `PRIVATE_KEY`: Deployer key for testnet deployments.
  - `CHAIN_RPC_URL`: Primary RPC endpoint (unified). Falls back to `SOMNIA_RPC_URL`/`DUCKCHAIN_RPC_URL` if set.
  - `CHAIN_ID`: Optional numeric chain id; Hardhat uses if provided.
  - Legacy still supported: `SOMNIA_TESTNET_RPC_URL`, `DUCKCHAIN_TESTNET_RPC_URL`.
  - Optional token addresses if pre-existing: `BASE_TOKEN_ADDRESS`, `PAYMENT_TOKEN_ADDRESS`, `TREASURY_ADDRESS`.

- Frontend (`client/.env.local` or `.env`): supports both `VITE_` and `APP_` prefixes.
  - API:
    - `VITE_API_BASE_URL` or `APP_API_BASE_URL` (default `http://localhost:3001`).
  - RPC:
    - `VITE_RPC_URL` or `APP_RPC_URL` (local default `http://127.0.0.1:8545/`).
    - `VITE_CHAIN_ID` and `VITE_CHAIN_NAME` optional for UI labels and network helpers.
    - `VITE_BLOCK_EXPLORER` optional link base for tx/address pages.
  - Addresses (auto-written by `scripts/sync-addresses.js`):
    - Agent: `VITE_AGENT_ADDRESS` or `APP_AGENT_ADDRESS`
    - Vault: `VITE_VAULT_ADDRESS` or `APP_VAULT_ADDRESS`
    - Base token: `VITE_BASE_TOKEN_ADDRESS` or `APP_BASE_TOKEN_ADDRESS` (local `WUSD`)
    - Payment token: `VITE_PAYMENT_TOKEN_ADDRESS` or `APP_PAYMENT_TOKEN_ADDRESS` (local `WPMT`)
  - IPFS:
    - `VITE_IPFS_GATEWAY` defaults to `https://nftstorage.link/ipfs/` for consistency with backend.
  - Note: Vite defaults to exposing `VITE_` vars; we configured `client/vite.config.ts` with `envPrefix: ['VITE_', 'APP_']` to also expose `APP_` vars.

- Backend (`server/.env`):
  - Unified: `CHAIN_RPC_URL`, `CHAIN_ID`, `CHAIN_NETWORK` (label), `PRIVATE_KEY` for signer.
  - Backwards compatible fallbacks supported for `SOMNIA_*`, `BLOCKCHAIN_*`, and `SEI_*`.
  - IPFS:
    - `IPFS_PROVIDER` defaults to `nft.storage` with `NFT_STORAGE_API_KEY`.
    - Optional Pinata: set `IPFS_PROVIDER=pinata` and provide `IPFS_PINATA_API_KEY`, `IPFS_PINATA_SECRET_KEY`.
    - `IPFS_GATEWAY_URL` defaults to `https://nftstorage.link/ipfs/`.
  - Contract addresses: fill from `contracts/deployment.json`.

## Local Quickstart

- Start local chain:
  - `cd contracts && npx hardhat node`
- Deploy core contracts to localhost:
  - `npx hardhat run --network localhost scripts/deploy.js`
  - This writes addresses to `contracts/deployment.json`.
- Create an agent and seed the vault:
  - `npx hardhat run --network localhost scripts/createAgent.js`
  - Grants roles and funds the Vault with test tokens.
- Sync addresses to the frontend:
  - `node ../scripts/sync-addresses.js`
  - Creates/updates `client/.env.local` with Agent/Vault/token addresses.
- Backend (server):
  - `cd ../server && npm install`
  - Copy `env.example` to `.env` and fill minimal values (RPC `http://127.0.0.1:8545/`, addresses from `contracts/deployment.json`)
  - `npm run start:dev`
- Frontend (client):
  - `cd ../client && npm install`
  - Ensure `.env.local` contains either `VITE_` or `APP_` variables.
  - `npm run dev` (opens `http://localhost:5173/`)
  - Interact with “Blockchain Verification” section to see addresses.

## Testnet Setup

- Set `contracts/.env`:
  - `PRIVATE_KEY`, RPC URL (Somnia or Sei EVM), optional pre-existing token addresses.
- Deploy:
  - `npx hardhat run --network somniaTestnet scripts/deploy.js`
- Create agent:
  - `npx hardhat run --network somniaTestnet scripts/createAgent.js`
- Sync frontend env:
  - `node scripts/sync-addresses.js`
  - Update `client/.env.local` with API base URL for your backend and chain explorer links if needed.

## Contracts Deep Dive

- Vault:
  - Performs swaps through adapters set by governance/admin.
  - Enforces `minAmountOut` and emits `Swap` events.
  - Holds balances for base and payment tokens.
- MemoryContract:
  - `DEFAULT_ADMIN_ROLE` is granted to deployer in constructor.
  - `AGENT_ROLE` exists and is granted to agent proxies to write memory/trade records.
  - Key structs: `TradeRecord`, `LearningWeights`. Key mappings: `agentStates`, `tradeHistory`, `preferences`.
  - Example method: `recordTrade` persists trade outcomes.
- AgentLogic:
  - Public `buy` and `sell` call `Vault.swap` and emit `TradeExecuted`.
  - `rebalancePortfolio` provides rebalancing logic.
- AgentFactory & Registry:
  - Factory deploys agent proxies; Registry tracks them and supports role coordination.

## Demo Trading & Adapters

- To execute real swaps, set a swap adapter on the `Vault` compatible with your DEX/router on the target chain.
- Local demo can use mocks (router/oracle) and configure the adapter for preview.
- After adapter configuration, invoke `AgentLogic.buy` or `sell` (via backend or direct script) with `minAmountOut` for slippage protection.

## Frontend Integration Notes

- Wallet: MetaMask support is built-in; pages use Somnia/Sei testnet configs and display blockchain sections.
- Local Hardhat: Chain ID is typically `31337`. Frontend logic may treat Somnia/Sei as testnet; adjust UI logic if you want special labels for local dev.
- `InteractSoul` reads `VITE_` and `APP_` env vars to display Agent/Vault/Base/Payment addresses.

## Backend Integration Notes

- Start with `npm run start:dev`.
- Provide RPC and contract addresses via `.env`.
- The backend exposes endpoints for agents, trading, memory, marketplace, and IPFS. Reference code in `server/src` folders for specifics.

## Scripts

- `contracts/scripts/deploy.js`: Deploys core contracts with Ethers v6 compatibility.
- `contracts/scripts/createAgent.js`: Creates agent proxy, grants roles, seeds Vault balances, updates `deployment.json` with agent address.
- `scripts/sync-addresses.js`: Writes addresses from `contracts/deployment.json` to `client/.env.local` with both `VITE_` and `APP_` prefixes.

## Troubleshooting

- Ethers v6 argument errors (e.g., `unsupported addressable value`):
  - Ensure you use `contract.getAddress()` and `waitForDeployment()` instead of v5-style properties.
  - Double-check you pass actual addresses, not `undefined` or object references.
- Agent creation issues:
  - Use `registry.getOwnerAgents` to fetch agent addresses rather than parsing logs.
  - Confirm roles are granted to the Agent in both `Vault` and `MemoryContract`.
- Frontend env not loading:
  - The app supports `VITE_` and `APP_` prefixes (`envPrefix` set in `vite.config.ts`).
  - Re-run `node scripts/sync-addresses.js` after redeployments.
  - Restart Vite dev server after changing env files.
- Chain mismatch:
  - Ensure MetaMask is connected to the correct chain (Somnia/Sei testnet or local Hardhat).
  - For local, RPC should be `http://127.0.0.1:8545/`.

## Glossary

- Base token: The asset the agent primarily holds/trades (local `WUSD`).
- Payment token: The quote/fee asset for swaps (local `WPMT`).
- Adapter: Contract that routes swaps through a DEX/router.
- Agent proxy: Upgradeable instance of `AgentLogic` deployed via `AgentFactory`.
- Registry: Keeps track of agents and versions.

## Support & Maintenance

- Redeploy sequence if issues arise:
  - Keep Hardhat node running: `npx hardhat node`
  - Deploy: `npx hardhat run --network localhost scripts/deploy.js`
  - Create agent: `npx hardhat run --network localhost scripts/createAgent.js`
  - Sync FE env: `node scripts/sync-addresses.js`
- For testnets, verify addresses on the explorer and set correct RPC URLs.

## License

- No license specified. For hackathon/demo purposes only.