# Wishpers — Technical Documentation

This document provides a formal, comprehensive overview of the Wishpers project: architecture, smart contracts, deployment, environment configuration, local/testnet setup, integration notes, and troubleshooting.

## Overview

- Wishpers is an AI-agent and trading demo comprising Solidity smart contracts, a NestJS backend, and a React/Vite frontend.
- Local development uses Hardhat; testnet targets include Somnia and compatible EVM networks.

## Components

- Smart contracts (Solidity): `Vault`, `MemoryContract`, `Strategy`, `AgentLogic` (implementation), `AgentFactory`, `AgentRegistry`, `Marketplace`.
- Backend (NestJS): Wallet authentication, agent orchestration, marketplace endpoints, IPFS integration.
- Frontend (React/Vite): Wallet connection, agent (“Soul”) interaction, marketplace and dashboard views.

## Smart Contracts

- `Vault`: Holds funds, performs swaps via configured adapters, enforces slippage, tracks balances.
- `MemoryContract`: Persists agent state, trade history, and preferences. Role-managed (`DEFAULT_ADMIN_ROLE`, `AGENT_ROLE`).
- `Strategy`: Holds strategy parameters consumed by `AgentLogic`.
- `AgentLogic` (implementation): Exposes trading actions (`buy`, `sell`, `rebalancePortfolio`); agents are deployed as proxies wired to `Vault` and `MemoryContract`.
- `AgentFactory`: Deploys agent proxies and wires required dependencies.
- `AgentRegistry`: Tracks deployed agents, versions, and ownership.
- `Marketplace`: Basic marketplace surface for listing and upgrades.

### Deployed Addresses (current `contracts/deployment.json`)

- Network: `custom`
- Deployer: `0x2FF91E6FE477159A84fe4208C6cA9601c68935D4`
- Treasury: `0x2ff91e6fe477159a84fe4208c6ca9601c68935d4`
- Tokens
  - Base token: `0x687c3341bFc16Da642F6b7B3978cfdba664CFe7f`
  - Payment token: `0x0000000000000000000000000000000000000000` (native)
  - Extra
    - ATOM: `0x832b2f5Fb2ff002eFA8b1A7e080C27832b44A97A`
    - WETH: `0x439168CaB962ac8936581bdB0f2f5B9285383eBB`
- Contracts
  - Vault: `0x5901296BC6899c82508De27c49a39751941670Ce`
  - MemoryContract: `0x8A29312daDd8D2c55c6B2a225ef866781b0a57bC`
  - Strategy: `0xaEd89E1791d91165380b9D21Dec2d8436FdB7b7D`
  - AgentLogicImplementation: `0x6165Af782F8b2B7a311fb3D1480Bcde3F7c9698c`
  - AgentRegistry: `0x2eEE28f82F1f29e78057A3815Ac500202Ef3F1EA`
  - AgentFactory: `0xbfe59958Bf52e35d7600A08b1300ea59DA55E1Eb`
  - Marketplace: `0x5E957199360388cC0B678a858e26E58dA9aedcA3`

## Repository Layout

- Contracts: `contracts/`
- Frontend: `client/`
- Backend: `server/`
- Address sync script: `scripts/sync-addresses.js`

## Environment Configuration

- Contracts (`contracts/.env`)
  - `PRIVATE_KEY`: Deployer key for testnet deployments.
  - `CHAIN_RPC_URL`: RPC endpoint. Optional `CHAIN_ID` for explicit chain ID.
  - Optional token addresses: `BASE_TOKEN_ADDRESS`, `PAYMENT_TOKEN_ADDRESS`, `TREASURY_ADDRESS`.

- Frontend (`client/.env.local` or `.env`)
  - API base URL: `APP_API_BASE_URL` or `VITE_API_BASE_URL` (default `http://localhost:3001`).
  - RPC: `APP_RPC_URL` or `VITE_RPC_URL` (local default `http://127.0.0.1:8545/`).
  - Addresses (set by `scripts/sync-addresses.js`): `APP_AGENT_ADDRESS`/`VITE_AGENT_ADDRESS`, `APP_VAULT_ADDRESS`/`VITE_VAULT_ADDRESS`, `APP_BASE_TOKEN_ADDRESS`/`VITE_BASE_TOKEN_ADDRESS`, `APP_PAYMENT_TOKEN_ADDRESS`/`VITE_PAYMENT_TOKEN_ADDRESS`.
  - IPFS gateway: `VITE_IPFS_GATEWAY` (default `https://nftstorage.link/ipfs/`).

- Backend (`server/.env`)
  - `CHAIN_RPC_URL`, `CHAIN_ID`, optional `CHAIN_NETWORK` label, `PRIVATE_KEY`.
  - IPFS provider: `IPFS_PROVIDER` (`nft.storage` default) and associated API keys.
  - Contract addresses: sourced from `contracts/deployment.json` or set explicitly.

## Local Development

- Start local chain: `cd contracts && npx hardhat node`
- Deploy core contracts: `npx hardhat run --network localhost scripts/deploy.js`
- Create an agent: `npx hardhat run --network localhost scripts/createAgent.js`
- Sync frontend env: `node scripts/sync-addresses.js`
- Backend: `cd server && npm install && npm run start:dev`
- Frontend: `cd client && npm install && npm run dev` (opens `http://localhost:5173/`)

## Testnet Deployment

- Configure `contracts/.env` with `PRIVATE_KEY`, `CHAIN_RPC_URL`, and optional token addresses.
- Deploy: `npx hardhat run --network somniaTestnet scripts/deploy.js`
- Create agent: `npx hardhat run --network somniaTestnet scripts/createAgent.js`
- Sync frontend env: `node scripts/sync-addresses.js`

## Scripts

- `contracts/scripts/deploy.js`: Deploys core contracts.
- `contracts/scripts/createAgent.js`: Creates agent proxy, grants roles, seeds Vault balances.
- `scripts/sync-addresses.js`: Writes addresses from `contracts/deployment.json` to `client/.env.local` (both `APP_` and `VITE_`).

## Integration Notes

- Frontend supports MetaMask; ensure correct chain selection (local Hardhat `31337` by default).
- Vite exposes both `APP_` and `VITE_` env vars via `envPrefix` configuration.
- Backend uses CORS with default allowed origins: `http://localhost:5173`, `http://localhost:5174`, `http://localhost:3000`.

## Troubleshooting

- RPC/Chain ID mismatch: ensure `CHAIN_ID` matches `eth_chainId` of the RPC.
- Env not loading: restart the Vite dev server after changing `.env` files; re-run `scripts/sync-addresses.js` after redeployments.
- Agent roles: confirm Agent has required roles in `Vault` and `MemoryContract`.
- Ethers v6 usage: use `getAddress()`/`waitForDeployment()` patterns.

## License

- This project is licensed under the MIT License. See `LICENSE` for details.