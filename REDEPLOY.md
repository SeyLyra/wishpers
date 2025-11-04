# Re-Deployment Guide - MockUSDC (6 Decimals)

## What Changed?

✅ **MockUSDC** created with 6 decimals (like real USDC)
✅ Deployment script updated to use MockUSDC for base token
✅ Backend faucet service supports both 6 and 18 decimal tokens
✅ Soul lookup fixed (supports both MongoDB _id and contract address)

## Quick Re-Deploy

### 1. Compile New Contract
```bash
cd contracts
npx hardhat compile
```

### 2. Deploy to Somnia Testnet
```bash
npx hardhat run scripts/deploy.js --network custom
```

**Expected Output:**
```
🪙 Deploying Mock USDC token (USDC) with faucet...
✅ Mock USDC deployed at: 0x...
   Faucet: 1000 USDC per claim, 0s cooldown, 6 decimals

🪙 Deploying extra mock tokens with faucet...
🪙 Deploying Cosmos ATOM (Test) token (ATOM) with faucet...
✅ Cosmos ATOM (Test) deployed at: 0x...
   Faucet: 100 ATOM per claim, 0s cooldown, 18 decimals

🪙 Deploying Wrapped ETH (Test) token (WETH) with faucet...
✅ Wrapped ETH (Test) deployed at: 0x...
   Faucet: 10 WETH per claim, 0s cooldown, 18 decimals

💰 Deploying Vault...
✅ Vault: 0x...

... (rest of contracts)
```

### 3. Update Backend Configuration

The deployment script automatically updates `contracts/deployment.json`. Copy the new addresses to your `server/.env`:

```bash
# From contracts/deployment.json
BASE_TOKEN_ADDRESS=<new-usdc-address>
ATOM_TOKEN_ADDRESS=<new-atom-address>
WETH_TOKEN_ADDRESS=<new-weth-address>
VAULT_ADDRESS=<new-vault-address>
# ... other addresses
```

### 4. Restart Backend
```bash
cd server
pnpm start:dev
```

### 5. Test Faucet

Visit `http://localhost:5173/faucet` and claim tokens:
- **USDC**: Should receive 1000.00 USDC (displayed correctly with 6 decimals)
- **ATOM**: Should receive 100.0 ATOM
- **WETH**: Should receive 10.0 WETH

---

## Verification Checklist

### ✅ Smart Contracts
- [ ] MockUSDC deployed with 6 decimals
- [ ] ATOM deployed with 18 decimals
- [ ] WETH deployed with 18 decimals
- [ ] Vault uses new USDC as base token
- [ ] All contract addresses in deployment.json

### ✅ Backend Configuration
- [ ] server/.env updated with new addresses
- [ ] Backend compiles without TypeScript errors
- [ ] Backend starts successfully
- [ ] Contracts service loads all contracts
- [ ] Wallet connected message in logs

### ✅ Frontend Testing
- [ ] Faucet page loads correctly
- [ ] Can claim USDC → shows 1000.00 (not 1M)
- [ ] Can claim ATOM → shows 100.0
- [ ] Can claim WETH → shows 10.0
- [ ] Token balances display with correct decimals

### ✅ Soul Operations
- [ ] Can create new soul
- [ ] Soul uses USDC in vault
- [ ] Can deposit USDC to soul's vault
- [ ] Portfolio displays correct amounts

### ✅ Marketplace
- [ ] Can list soul for sale (using STT)
- [ ] Price displays correctly in STT
- [ ] Can buy soul with STT
- [ ] Platform fee calculated correctly (2.5%)

---

## Troubleshooting

### "Insufficient funds" when deploying
**Solution:** Make sure deployer wallet has enough STT for gas
```bash
# Check balance
curl https://dream-rpc.somnia.network -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["YOUR_ADDRESS","latest"],"id":1}'
```

### Contract address not found in .env
**Solution:** Copy addresses from `contracts/deployment.json` to `server/.env`

### TypeScript errors in backend
**Solution:** Rebuild backend
```bash
cd server
rm -rf dist
pnpm run build
pnpm start:dev
```

### USDC still showing wrong decimals
**Solution:**
1. Verify MockUSDC.decimals() returns 6
2. Check frontend uses formatUnits(balance, 6) for USDC
3. Clear browser cache and reload

### Faucet claim fails
**Solution:** Check backend logs for errors
```bash
# In server logs, look for:
"Faucet wallet connected: 0x..."
"Loaded token contract at 0x..."
```

---

## Rollback (If Needed)

If you need to rollback to old deployment:

1. Restore old addresses in `server/.env`
2. Restart backend
3. Frontend will work with 18-decimal USDC (just displays bigger numbers)

---

## Next Steps After Re-Deploy

1. **Update DEPLOYED_ADDRESSES.md** with new contract addresses
2. **Test all features** end-to-end
3. **Create test souls** with USDC portfolios
4. **Test marketplace** with STT payments
5. **Verify yield optimizer** works with new USDC

---

## Summary

| Before | After |
|--------|-------|
| USDC: 18 decimals | USDC: 6 decimals ✅ |
| 1000 USDC = 1,000,000,000,000,000,000,000 wei | 1000 USDC = 1,000,000,000 wei ✅ |
| Displays as 1 million | Displays as 1000.00 ✅ |
| Unrealistic for stablecoin | Matches real USDC ✅ |

**The new MockUSDC is production-ready for realistic testing!** 🚀
