require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    // Local development
    hardhat: {
      chainId: 1337,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
        count: 10,
      },
    },
    
    // Sei Testnet
    "sei-testnet": {
      url: process.env.SEI_TESTNET_RPC_URL || "https://sei-testnet-rpc-url",
      chainId: parseInt(process.env.SEI_TESTNET_CHAIN_ID) || 713715,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
      gas: "auto",
    },
    
    // Sei Mainnet
    "sei-mainnet": {
      url: process.env.SEI_MAINNET_RPC_URL || "https://sei-mainnet-rpc-url",
      chainId: parseInt(process.env.SEI_MAINNET_CHAIN_ID) || 713715,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
      gas: "auto",
    },
    
    // Local Sei Network (if running locally)
    "sei-local": {
      url: process.env.SEI_LOCAL_RPC_URL || "http://localhost:26657",
      chainId: parseInt(process.env.SEI_LOCAL_CHAIN_ID) || 1337,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
      gas: "auto",
    },
  },
  
  // Gas reporter configuration
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    token: "SEI",
    gasPrice: 1,
  },
  
  // Contract verification
  etherscan: {
    apiKey: {
      // Add API keys for different networks if needed
      sei: process.env.SEI_SCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "sei-testnet",
        chainId: 713715,
        urls: {
          apiURL: "https://sei-testnet-api-url",
          browserURL: "https://sei-testnet-explorer-url",
        },
      },
      {
        network: "sei-mainnet",
        chainId: 713715,
        urls: {
          apiURL: "https://sei-mainnet-api-url",
          browserURL: "https://sei-mainnet-explorer-url",
        },
      },
    ],
  },
  
  // Paths
  paths: {
    sources: "./",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  
  // Compiler settings
  compilers: [
    {
      version: "0.8.19",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        viaIR: true,
      },
    },
  ],
  
  // Mocha configuration
  mocha: {
    timeout: 40000,
  },
  
  // TypeChain configuration
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
  },
}; 