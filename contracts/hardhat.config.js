require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: { enabled: true, runs: 200 }
        }
      },
      {
        version: "0.8.21",
        settings: {
          optimizer: { enabled: true, runs: 200 }
        }
      },
      {
        version: "0.8.22",
        settings: {
          optimizer: { enabled: true, runs: 200 }
        }
      },
      {
        version: "0.8.24",
        settings: {
          optimizer: { enabled: true, runs: 200 }
        }
      }
    ]
  },
  paths: {
    sources: "./core",
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    duckchain: {
      url: process.env.DUCKCHAIN_RPC_URL || "https://rpc.duckchain.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1234, // Replace with actual DuckChain chain ID
      gasPrice: 20000000000, // 20 gwei
    },
    duckchainTestnet: {
      url: process.env.DUCKCHAIN_TESTNET_RPC_URL || "https://testnet.duckchain.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 5678, // Replace with actual DuckChain testnet chain ID
      gasPrice: 20000000000, // 20 gwei
    },
    somnia: {
      url: process.env.SOMNIA_RPC_URL || "https://dream-rpc.somnia.network",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      // chainId optional; set if known
      // gasPrice optional; Hardhat will estimate
    },
    somniaTestnet: {
      url: process.env.SOMNIA_TESTNET_RPC_URL || process.env.CHAIN_RPC_URL || "https://dream-rpc.somnia.network",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: process.env.CHAIN_ID ? Number(process.env.CHAIN_ID) : 50312,
      // gasPrice optional; Hardhat will estimate
    },
    // Unified custom network: reads CHAIN_RPC_URL and PRIVATE_KEY
    custom: {
      url: process.env.CHAIN_RPC_URL || process.env.SOMNIA_RPC_URL || "http://127.0.0.1:8545",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      // Optionally specify chainId via CHAIN_ID
      chainId: process.env.CHAIN_ID ? Number(process.env.CHAIN_ID) : undefined,
    },
  },
  etherscan: {
    apiKey: {
      duckchain: process.env.DUCKCHAIN_API_KEY || "",
      duckchainTestnet: process.env.DUCKCHAIN_TESTNET_API_KEY || "",
      somnia: process.env.SOMNIA_API_KEY || "",
      somniaTestnet: process.env.SOMNIA_TESTNET_API_KEY || ""
    },
    customChains: [
      {
        network: "duckchain",
        chainId: 1234,
        urls: {
          apiURL: "https://explorer.duckchain.com/api",
          browserURL: "https://explorer.duckchain.com"
        }
      },
      {
        network: "duckchainTestnet",
        chainId: 5678,
        urls: {
          apiURL: "https://testnet-explorer.duckchain.com/api",
          browserURL: "https://testnet-explorer.duckchain.com"
        }
      },
      {
        network: "somnia",
        chainId: 50312, // Update when mainnet is published
        urls: {
          apiURL: "https://shannon-explorer.somnia.network/api",
          browserURL: "https://shannon-explorer.somnia.network"
        }
      },
      {
        network: "somniaTestnet",
        chainId: 50312,
        urls: {
          apiURL: "https://shannon-explorer.somnia.network/api",
          browserURL: "https://shannon-explorer.somnia.network"
        }
      }
    ]
  }
};