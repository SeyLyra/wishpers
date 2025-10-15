# Smart Contracts for Immortal AI Souls

This directory contains all smart contracts for the Immortal AI Souls on Chain dApp.

## 📁 Directory Structure

```
contracts/
├── README.md                    # This file
├── ImmortalSouls.sol           # Main soul NFT contract
├── SoulFactory.sol             # Soul creation and management
├── SoulMarketplace.sol         # Trading and marketplace
├── SoulInheritance.sol         # Inheritance system
├── SoulUpgrades.sol            # Upgrade system
├── interfaces/                  # Contract interfaces
│   ├── ISoul.sol
│   ├── ISoulFactory.sol
│   └── ISoulMarketplace.sol
├── libraries/                   # Shared libraries
│   ├── SoulTraits.sol
│   └── SoulUtils.sol
├── test/                        # Contract tests
│   ├── ImmortalSouls.test.js
│   └── SoulFactory.test.js
├── scripts/                     # Deployment scripts
│   ├── deploy.js
│   └── verify.js
├── hardhat.config.js            # Hardhat configuration
├── package.json                 # Contract dependencies
└── .env                         # Contract environment variables
```

## 🚀 Getting Started

### 1. Install Dependencies
```bash
cd contracts
npm install
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env with your private keys and RPC URLs
```

### 3. Compile Contracts
```bash
npx hardhat compile
```

### 4. Run Tests
```bash
npx hardhat test
```

### 5. Deploy to Sei Network
```bash
npx hardhat run scripts/deploy.js --network sei-testnet
```

## 🔧 Contract Features

- **Soul Minting**: Create unique AI souls with IPFS metadata
- **Soul Merging**: Combine multiple souls into hybrid souls
- **Inheritance System**: On-chain will and inheritance management
- **Trading**: Soul marketplace with AI-powered pricing
- **Upgrades**: Soul enhancement system
- **IPFS Integration**: Decentralized metadata storage

## 🌐 Networks

- **Sei Testnet**: For development and testing
- **Sei Mainnet**: For production deployment
- **Local Hardhat**: For local development

## 📚 Documentation

See individual contract files for detailed documentation and usage examples. 