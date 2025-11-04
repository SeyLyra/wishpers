# 🚀 Startup Guide - Wishpers QUACK Edition

## ✅ Prerequisites Check

- [x] MongoDB running
- [x] Contract addresses configured in `server/.env`
- [x] All contracts deployed to Somnia testnet
- [x] Yield optimizer updated to Protocol A, B, C

## 📦 Installation & Startup

### 1. Install pnpm (if not already installed)
```bash
npm install -g pnpm
```

### 2. Install Dependencies
```bash
# Install all dependencies from root
pnpm install
```

### 3. Start Backend Server
```bash
cd server
pnpm start

# Or in development mode with hot reload
pnpm start:dev
```

**Expected output:**
- Server running on http://localhost:3001
- MongoDB connected
- Contracts loaded (AgentRegistry, Vault, MemoryContract, Marketplace)
- Wallet connected: 0x2FF91E6FE477159A84fe4208C6cA9601c68935D4

### 4. Start Frontend (in new terminal)
```bash
cd client
pnpm dev
```

**Expected output:**
- Frontend running on http://localhost:5173 (or 3000)
- Vite dev server started

## 🧪 Testing the Features

### 1. Test Faucet
1. Open http://localhost:5173/faucet
2. Click "Claim" on Mock USDC, ATOM, or WETH
3. Should receive tokens without cooldown

### 2. Test Soul Creation
1. Navigate to Create Soul page
2. Fill in name, personality, initial memory
3. Upload image
4. Create soul - should deploy AgentLogic proxy

### 3. Test Soul Marketplace
1. Go to My Souls page
2. Click "Sell" on any soul
3. Set price in STT
4. List on marketplace
5. Navigate to Marketplace to see listing

### 4. Test Yield Optimizer
1. Check API endpoint: http://localhost:3001/api/yield-optimizer/protocols
2. Should see Protocol A, B, C with APY rates

### 5. Test Trading
1. Check portfolio: http://localhost:3001/api/trading/portfolio/:soulId
2. View trading history

## 🔍 Troubleshooting

### Backend won't start
```bash
# Check if port 3001 is in use
lsof -i :3001

# Kill process if needed
kill -9 <PID>

# Check MongoDB
brew services list | grep mongodb
```

### Frontend won't start
```bash
# Check if port 5173/3000 is in use
lsof -i :5173

# Clear cache and reinstall
rm -rf node_modules .next
pnpm install
```

### Contract connection errors
- Verify `.env` has correct contract addresses from `DEPLOYMENT_CONFIG.md`
- Check RPC URL is accessible: `curl https://dream-rpc.somnia.network`
- Verify private key format (should start with 0x or be 64 hex chars)

### TypeScript errors
```bash
cd server
pnpm run build

cd ../client
pnpm run build
```

## 📝 API Endpoints

### Faucet
- `POST /api/faucet/mint` - Claim tokens (requires JWT)

### Trading
- `GET /api/trading/portfolio/:soulId` - Get portfolio
- `GET /api/trading/history/:soulId` - Get trade history
- `GET /api/trading/pairs` - Get trading pairs
- `GET /api/trading/price/:token` - Get token price

### Yield Optimizer
- `GET /api/yield-optimizer/protocols` - List all protocols
- `GET /api/yield-optimizer/best?token=USDC&maxRiskScore=5` - Get best protocol
- `POST /api/yield-optimizer/allocation` - Calculate optimal allocation
- `POST /api/yield-optimizer/rebalance` - Execute rebalance

### Marketplace
- `GET /api/marketplace/souls` - Get soul listings
- `POST /api/marketplace/souls/list` - List soul for sale (requires JWT)
- `POST /api/marketplace/souls/:listingId/buy` - Buy soul (requires JWT)
- `POST /api/marketplace/souls/:listingId/delist` - Delist soul (requires JWT)

### Souls
- `GET /api/souls` - Get all souls (requires JWT)
- `POST /api/souls` - Create new soul (requires JWT)
- `GET /api/souls/:id` - Get soul details
- `POST /api/souls/:id/chat` - Chat with soul (requires JWT)

## 🎯 Next Steps After Startup

1. **Test token faucet** - Make sure users can claim test tokens
2. **Create test souls** - Generate a few AI souls with different personalities
3. **Test marketplace** - List and buy souls to verify the flow
4. **Check yield optimizer** - Verify Protocol A/B/C are showing correct APY
5. **Test trading** - Execute some swaps through the vault
6. **Monitor logs** - Watch for any errors in backend console

## 🌐 Deployed Contracts

All contracts are deployed on **Somnia Testnet (Chain ID: 50312)**

See [DEPLOYMENT_CONFIG.md](DEPLOYMENT_CONFIG.md) for full list of addresses.

## 🔗 Links

- Frontend: http://localhost:5173
- Backend API: http://localhost:3001
- Backend Health: http://localhost:3001/health
- Somnia Explorer: https://shannon-explorer.somnia.network

---

**Status**: ✅ Ready to launch!

Run `pnpm install` from root, then start server and client.
