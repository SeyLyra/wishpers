# Deployment Configuration

## Essential Contract Addresses (from deployment.json)

Copy these addresses to your `server/.env` file:

```env
# ========================================
# BLOCKCHAIN (Unified)
# ========================================
CHAIN_RPC_URL=https://dream-rpc.somnia.network
CHAIN_ID=50312
PRIVATE_KEY=your-private-key-here

# ========================================
# CONTRACT ADDRESSES (DEPLOYED)
# ========================================
AGENT_REGISTRY_ADDRESS=0x60f9709fe48A52206195dB5a88e3b27b6db6E193
AGENT_FACTORY_ADDRESS=0x036993da05C13b57Cf143ACE7553C9a0059E2c40
VAULT_ADDRESS=0xA473bc736Ba0Fa20226FbBB0837C36c98ee52047
STRATEGY_ADDRESS=0x65a6b916cfA805293Fa6fFf1D908388FdD620c69
MEMORY_CONTRACT_ADDRESS=0xB27Bc3EBf57259981E511EFE16559b64F1d8dBc6
MARKETPLACE_ADDRESS=0xEFAB6d7C927aaC0fEFEa481D32618d4dc451Ef2E

# ========================================
# TOKEN ADDRESSES
# ========================================
# Base Token (Mock USDC)
BASE_TOKEN_ADDRESS=0xCc61e888bE53631067Ec828037894311d16795Cb
# Payment Token (Native STT - address(0))
PAYMENT_TOKEN_ADDRESS=0x0000000000000000000000000000000000000000
# Extra Tokens
ATOM_TOKEN_ADDRESS=0xAc234b3339dD04B2Fb4F5A9928544414707589Eb
WETH_TOKEN_ADDRESS=0x0a4FDabFF4c2249552397407eFBB7734ADf2b596

# ========================================
# ADAPTER ADDRESSES
# ========================================
SOMNIA_PRICE_ORACLE=0x9A1ECcA1292483576718a47e98Cc5321d6a426Dc
SOMNIA_STAKING_POOL=0x4a420eA84d7c033C34672E0f4bE9a73c66b60512
SOMNIA_LENDING_POOL=0x7C0d3174Db047E7eC5b7d24995241b961277ADae

# ========================================
# MOCK PROTOCOL ADDRESSES
# ========================================
MOCK_YIELD_FARM=0x7Aa2370b88e079dbF867013Be8162B3C7c2F0Bf7
MOCK_LENDING_POOL=0x79C047CEFAD85505434d93C193a7eADb0Ebb8321

# ========================================
# DEPLOYER INFO
# ========================================
DEPLOYER_ADDRESS=0x2FF91E6FE477159A84fe4208C6cA9601c68935D4
TREASURY_ADDRESS=0x2ff91e6fe477159a84fe4208c6ca9601c68935d4
```

## Client Configuration

Update your `client/.env` or `client/src/lib/api.ts` with:

```typescript
// Contract addresses for frontend
export const CONTRACTS = {
  MARKETPLACE: '0xEFAB6d7C927aaC0fEFEa481D32618d4dc451Ef2E',
  AGENT_FACTORY: '0x036993da05C13b57Cf143ACE7553C9a0059E2c40',
  AGENT_REGISTRY: '0x60f9709fe48A52206195dB5a88e3b27b6db6E193',
  VAULT: '0xA473bc736Ba0Fa20226FbBB0837C36c98ee52047',
};

// Token addresses
export const TOKENS = {
  BASE: '0xCc61e888bE53631067Ec828037894311d16795Cb', // Mock USDC
  ATOM: '0xAc234b3339dD04B2Fb4F5A9928544414707589Eb',
  WETH: '0x0a4FDabFF4c2249552397407eFBB7734ADf2b596',
};
```

## What's Ready

### ✅ Core Contracts
- **Vault**: Multi-token portfolio with swap functionality
- **Strategy**: Rebalancing with 5% threshold
- **AgentLogic**: UUPS upgradeable AI agent (implementation deployed)
- **AgentRegistry**: Soul registration and discovery
- **AgentFactory**: Create new AI agent instances
- **Marketplace**: Soul marketplace with 2.5% platform fee
- **MemoryContract**: On-chain learning and trade history

### ✅ Token System
- **Base Token (Mock USDC)**: For vault operations and trading
- **ATOM**: Test token for portfolio diversification
- **WETH**: Wrapped ETH for DeFi operations
- **Faucet**: All 3 tokens have claim functionality (no cooldown for testing)

### ✅ Adapters & Mocks
- **SomniaPriceOracleMock**: Price feeds
- **SomniaStakingAdapter**: Staking protocol integration
- **SomniaLendingAdapter**: Lending protocol integration
- **MockYieldFarm**: Test yield farming
- **MockLendingPool**: Test lending pool

### ✅ Backend Features
- Trading API (portfolio, history, market data)
- Yield Optimizer (Protocol A, B, C with 4.2%-8.2% APY)
- Marketplace API (list/buy/delist souls)
- Faucet API (claim tokens)
- Soul creation and management
- Memory and learning system

## Next Steps

1. **Update server/.env** with the addresses above
2. **Update client configuration** with contract addresses
3. **Start the backend**: `cd server && pnpm start`
4. **Start the frontend**: `cd client && pnpm dev`
5. **Test the faucet**: Navigate to `/faucet` and claim test tokens
6. **Create a soul**: Use the soul creation flow
7. **List a soul**: Try selling a soul on the marketplace

## Network Info
- **Network**: Somnia Testnet (Custom)
- **Chain ID**: 50312
- **RPC**: https://dream-rpc.somnia.network
- **Explorer**: https://shannon-explorer.somnia.network
- **Deployment Date**: 2025-11-04
