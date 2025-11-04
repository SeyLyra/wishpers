# Token Strategy - Wishpers QUACK Edition

## Token Usage Overview

### **STT (Native Token - address(0))**
- **Purpose**: Marketplace currency
- **Use Case**: Buying and selling AI Souls on the marketplace
- **Platform Fee**: 2.5% on all soul sales
- **Decimals**: 18 (native token)
- **Source**: Users' native blockchain balance

**Example:**
```solidity
// Listing a soul for 100 STT
marketplace.listSoul(soulAddress, "My Soul", "description", "ipfs://", 100 ether);

// Buying requires sending STT value
marketplace.purchaseItem{value: 100 ether}(itemId);
```

---

### **USDC (Mock USDC - 6 decimals)**
- **Purpose**: Soul's portfolio/vault token
- **Use Cases**:
  - Trading in souls' portfolios
  - DeFi operations (lending, staking, liquidity)
  - Yield optimization
  - Vault deposits/withdrawals
- **Decimals**: 6 (like real USDC)
- **Faucet**: 1000 USDC per claim (no cooldown in testnet)

**Why 6 decimals?**
- Real USDC uses 6 decimals, not 18
- More realistic for stablecoin testing
- 1000 USDC = 1,000,000,000 (1000 * 10^6) in wei
- Displays correctly as 1000.00 USDC

---

### **ATOM (Cosmos Token - 18 decimals)**
- **Purpose**: Portfolio diversification token
- **Use Cases**:
  - Multi-token portfolio management
  - Cross-chain testing scenarios
  - Rebalancing demonstrations
- **Decimals**: 18
- **Faucet**: 100 ATOM per claim

---

### **WETH (Wrapped ETH - 18 decimals)**
- **Purpose**: DeFi operations token
- **Use Cases**:
  - DeFi protocol testing
  - Liquidity pool operations
  - Yield farming
- **Decimals**: 18
- **Faucet**: 10 WETH per claim

---

## Contract Breakdown

### MockUSDC.sol (NEW - 6 decimals)
```solidity
// Deployed as base token for vault/trading
contract MockUSDC is ERC20, Ownable {
    uint8 private constant DECIMALS = 6; // Real USDC decimals

    function claim() external;
    function claimFor(address recipient) external;
    function canClaim(address user) external view returns (bool, uint256);
}
```

**Key Features:**
- ✅ 6 decimals (matches real USDC)
- ✅ Faucet with configurable cooldown
- ✅ Owner can mint additional tokens
- ✅ 1M USDC initial supply to deployer

### FaucetToken.sol (18 decimals)
```solidity
// Used for ATOM and WETH
contract FaucetToken is ERC20, Ownable {
    // Uses default 18 decimals from ERC20

    function claim() external;
    function claimFor(address recipient) external;
}
```

---

## Deployment Configuration

### Before Deployment:
```bash
# contracts/.env
CHAIN_RPC_URL=https://dream-rpc.somnia.network
CHAIN_ID=50312
PRIVATE_KEY=your-private-key
TREASURY_ADDRESS=your-treasury-address
```

### Deploy Command:
```bash
cd contracts
npx hardhat run scripts/deploy.js --network custom
```

### What Gets Deployed:

1. **MockUSDC** (6 decimals)
   - Name: "Mock USDC"
   - Symbol: "USDC"
   - Faucet: 1000 USDC per claim
   - Cooldown: 0 seconds (testnet)

2. **FaucetToken - ATOM** (18 decimals)
   - Name: "Cosmos ATOM (Test)"
   - Symbol: "ATOM"
   - Faucet: 100 ATOM per claim

3. **FaucetToken - WETH** (18 decimals)
   - Name: "Wrapped ETH (Test)"
   - Symbol: "WETH"
   - Faucet: 10 WETH per claim

---

## Frontend Integration

### Display Token Balances:

```typescript
import { formatUnits } from 'ethers';

// For USDC (6 decimals)
const usdcBalance = await usdcContract.balanceOf(address);
const formattedUSDC = formatUnits(usdcBalance, 6); // "1000.00"

// For ATOM/WETH (18 decimals)
const atomBalance = await atomContract.balanceOf(address);
const formattedATOM = formatUnits(atomBalance, 18); // "100.0"
```

### Claim from Faucet:

```typescript
// USDC
const usdcContract = new Contract(USDC_ADDRESS, abi, signer);
const tx = await usdcContract.claim();
await tx.wait();
// User receives exactly 1000 USDC (1000 * 10^6 wei)

// ATOM
const atomContract = new Contract(ATOM_ADDRESS, abi, signer);
const tx = await atomContract.claim();
await tx.wait();
// User receives exactly 100 ATOM (100 * 10^18 wei)
```

---

## Backend API Integration

### Faucet Service

The backend automatically detects token decimals:

```typescript
// server/src/faucet/faucet.service.ts
const decimals = await tokenContract.decimals(); // Returns 6 for USDC, 18 for others
const faucetAmount = await tokenContract.faucetAmount();
// Amount is already in correct decimals from contract
```

**API Endpoint:**
```
POST /api/faucet/mint
{
  "tokenSymbol": "USDC",
  "tokenAddress": "0x...",
  "amount": "1000" // Not used - contract determines amount
}
```

---

## Testing Scenarios

### 1. Soul Portfolio Management
```
User creates soul → Vault uses USDC as base token
Soul deposits 1000 USDC → Shows 1000.00 USDC (not 1M)
Soul trades USDC ↔ ATOM → Multi-token portfolio
Soul rebalances → Maintains target allocations
```

### 2. Marketplace Transactions
```
User lists soul for 100 STT → Marketplace contract
Buyer purchases with 100 STT → 2.5 STT platform fee
Seller receives 97.5 STT → Soul ownership transfers
```

### 3. Yield Optimization
```
Soul has 1000 USDC → Check Protocol A/B/C
Protocol C offers 8.2% APY → Auto-rebalance
Soul deposits to Protocol C → Earns yield
Periodic rebalancing → Maximizes returns
```

---

## Migration Path (Old Deployments → New)

If you already deployed with 18-decimal USDC:

1. **Re-deploy contracts** with new MockUSDC
2. **Update .env** with new USDC address
3. **Update frontend** - no changes needed (formatUnits handles decimals)
4. **Clear old test data** from MongoDB if needed

```bash
# Re-deploy
cd contracts
npx hardhat run scripts/deploy.js --network custom

# Update server/.env with new BASE_TOKEN_ADDRESS
# Restart backend
cd ../server
pnpm start:dev
```

---

## Summary

| Token | Symbol | Decimals | Use Case | Faucet Amount |
|-------|--------|----------|----------|---------------|
| Native | STT | 18 | Marketplace (buy/sell souls) | User's wallet |
| Mock USDC | USDC | 6 | Soul portfolios, trading, DeFi | 1000 USDC |
| Cosmos | ATOM | 18 | Portfolio diversification | 100 ATOM |
| Wrapped ETH | WETH | 18 | DeFi operations | 10 WETH |

**Key Principle:**
- **STT = Soul trading** (marketplace)
- **USDC = Soul working** (portfolio, DeFi, yield)
