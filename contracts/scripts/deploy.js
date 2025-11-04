const { ethers, network } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying Wishpers core contracts...");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Network:", network.name);

  // Env configuration
  const BASE_TOKEN_ADDRESS = process.env.BASE_TOKEN_ADDRESS;
  const PAYMENT_TOKEN_ADDRESS = process.env.PAYMENT_TOKEN_ADDRESS; // unused; Marketplace will use native STT
  const TREASURY_ADDRESS = process.env.TREASURY_ADDRESS || deployer.address;

  // Helper to deploy token with faucet functionality
  async function ensureToken(address, name, symbol, faucetAmount, cooldown, useUSDC = false) {
    if (address && ethers.isAddress(address)) {
      console.log(`Using existing token for ${name}:`, address);
      return address;
    }
    console.log(`\n🪙 Deploying ${name} token (${symbol}) with faucet...`);

    let token;
    if (useUSDC) {
      // Deploy MockUSDC (6 decimals)
      const MockUSDC = await ethers.getContractFactory("MockUSDC");
      token = await MockUSDC.deploy(
        faucetAmount, // Amount per claim (in USDC, e.g., 1000)
        cooldown // Cooldown in seconds
      );
    } else {
      // Deploy FaucetToken (18 decimals)
      const FaucetToken = await ethers.getContractFactory("FaucetToken");
      token = await FaucetToken.deploy(
        name,
        symbol,
        ethers.parseEther(faucetAmount.toString()), // Amount per claim
        cooldown // Cooldown in seconds
      );
    }

    await token.waitForDeployment();
    const decimals = useUSDC ? 6 : 18;
    console.log(`✅ ${name} deployed at:`, await token.getAddress());
    console.log(`   Faucet: ${faucetAmount} ${symbol} per claim, ${cooldown}s cooldown, ${decimals} decimals`);
    return await token.getAddress();
  }

  // 1) Base Token (USDC for vault/trading) with faucet functionality
  // Faucet parameters: (address, name, symbol, faucetAmount, cooldownSeconds, useUSDC)
  const baseTokenAddress = await ensureToken(
    BASE_TOKEN_ADDRESS,
    "Mock USDC",
    "USDC",
    1000, // 1000 USDC per claim
    0,    // No cooldown for testing (set to 3600 for 1 hour, 86400 for 24 hours)
    true  // Use MockUSDC with 6 decimals
  );
  const paymentTokenAddress = ethers.ZeroAddress; // native STT for marketplace

  // 1b) Extra mock tokens for trading/rebalancing with faucet
  console.log("\n🪙 Deploying extra mock tokens with faucet...");
  const extraTokens = {};
  extraTokens.ATOM = await ensureToken(
    process.env.ATOM_TOKEN_ADDRESS,
    "Cosmos ATOM (Test)",
    "ATOM",
    100,  // 100 ATOM per claim
    0     // No cooldown for testing
  );
  extraTokens.WETH = await ensureToken(
    process.env.WETH_TOKEN_ADDRESS,
    "Wrapped ETH (Test)",
    "WETH",
    10,   // 10 WETH per claim
    0     // No cooldown for testing
  );

  // 2) Vault
  console.log("\n💰 Deploying Vault...");
  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(baseTokenAddress);
  await vault.waitForDeployment();
  console.log("✅ Vault:", await vault.getAddress());

  // Track the extra tokens in the Vault for portfolio management
  console.log("\n📦 Adding tracked tokens to Vault...");
  for (const [symbol, addr] of Object.entries(extraTokens)) {
    const tx = await vault.addTrackedToken(addr);
    await tx.wait();
    console.log(`✅ Tracked ${symbol}: ${addr}`);
  }

  // 3) MemoryContract
  console.log("\n🧠 Deploying MemoryContract...");
  const MemoryContract = await ethers.getContractFactory("MemoryContract");
  const memoryContract = await MemoryContract.deploy();
  await memoryContract.waitForDeployment();
  console.log("✅ MemoryContract:", await memoryContract.getAddress());

  // 4) Strategy
  console.log("\n📈 Deploying Strategy...");
  const Strategy = await ethers.getContractFactory("Strategy");
  const strategy = await Strategy.deploy(await vault.getAddress());
  await strategy.waitForDeployment();
  console.log("✅ Strategy:", await strategy.getAddress());

  // 5) AgentLogic implementation (UUPS)
  console.log("\n🤖 Deploying AgentLogic implementation...");
  const AgentLogic = await ethers.getContractFactory("AgentLogic");
  const agentLogicImpl = await AgentLogic.deploy();
  await agentLogicImpl.waitForDeployment();
  console.log("✅ AgentLogic implementation:", await agentLogicImpl.getAddress());

  // 6) AgentRegistry
  console.log("\n📇 Deploying AgentRegistry...");
  const AgentRegistry = await ethers.getContractFactory("AgentRegistry");
  const registry = await AgentRegistry.deploy();
  await registry.waitForDeployment();
  console.log("✅ AgentRegistry:", await registry.getAddress());

  // 7) AgentFactory
  console.log("\n🏭 Deploying AgentFactory...");
  const AgentFactory = await ethers.getContractFactory("AgentFactory");
  const factory = await AgentFactory.deploy(await registry.getAddress(), await agentLogicImpl.getAddress());
  await factory.waitForDeployment();
  console.log("✅ AgentFactory:", await factory.getAddress());

  // Grant factory role in registry
  console.log("\n🔐 Configuring roles...");
  const FACTORY_ROLE = await registry.AGENT_FACTORY_ROLE();
  await (await registry.grantRole(FACTORY_ROLE, await factory.getAddress())).wait();
  console.log("✅ AGENT_FACTORY_ROLE granted to AgentFactory");

  // 8) Marketplace
  console.log("\n🛍️ Deploying Marketplace...");
  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(paymentTokenAddress, TREASURY_ADDRESS);
  await marketplace.waitForDeployment();
  console.log("✅ Marketplace:", await marketplace.getAddress());

  // Save deployment info
  const deploymentInfo = {
    network: network.name,
    deployer: deployer.address,
    treasury: TREASURY_ADDRESS,
    tokens: {
      baseToken: baseTokenAddress,
      paymentToken: paymentTokenAddress,
      extra: extraTokens,
    },
    contracts: {
      Vault: await vault.getAddress(),
      MemoryContract: await memoryContract.getAddress(),
      Strategy: await strategy.getAddress(),
      AgentLogicImplementation: await agentLogicImpl.getAddress(),
      AgentRegistry: await registry.getAddress(),
      AgentFactory: await factory.getAddress(),
      Marketplace: await marketplace.getAddress(),
    },
    timestamp: new Date().toISOString(),
  };

  fs.writeFileSync("deployment.json", JSON.stringify(deploymentInfo, null, 2));
  console.log("\n📁 Deployment info saved to deployment.json");

  console.log("\n✅ Core deployment complete.");
  console.log("Next steps:");
  console.log("- Use AgentFactory to deploy agents via proxies (initialize with vault/memory).");
  console.log("- Optionally deploy governance (Timelock + Governance) with a votes-enabled token.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });