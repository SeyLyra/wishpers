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
  - `SOMNIA_TESTNET_RPC_URL` or `DUCKCHAIN_TESTNET_RPC_URL`: RPC endpoints for testnet.
  - Optional token addresses if pre-existing: `BASE_TOKEN_ADDRESS`, `PAYMENT_TOKEN_ADDRESS`, `TREASURY_ADDRESS`.

- Frontend (`client/.env.local` or `.env`): supports both `VITE_` and `APP_` prefixes.
  - API:
    - `VITE_API_BASE_URL` or `APP_API_BASE_URL` (default `http://localhost:3001`).
  - RPC:
    - `VITE_RPC_URL` or `APP_RPC_URL` (local default `http://127.0.0.1:8545/`).
  - Addresses (auto-written by `scripts/sync-addresses.js`):
    - Agent: `VITE_AGENT_ADDRESS` or `APP_AGENT_ADDRESS`
    - Vault: `VITE_VAULT_ADDRESS` or `APP_VAULT_ADDRESS`
    - Base token: `VITE_BASE_TOKEN_ADDRESS` or `APP_BASE_TOKEN_ADDRESS` (local `WUSD`)
    - Payment token: `VITE_PAYMENT_TOKEN_ADDRESS` or `APP_PAYMENT_TOKEN_ADDRESS` (local `WPMT`)
  - Note: Vite defaults to exposing `VITE_` vars; we configured `client/vite.config.ts` with `envPrefix: ['VITE_', 'APP_']` to also expose `APP_` vars.

- Backend (`server/.env`):
  - See `server/env.example`. Provide RPC URL and contract addresses from `contracts/deployment.json`.

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