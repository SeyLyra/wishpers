const { ethers, network } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying Wishpers core contracts...");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Network:", network.name);

  // Env configuration
  const BASE_TOKEN_ADDRESS = process.env.BASE_TOKEN_ADDRESS;
  const PAYMENT_TOKEN_ADDRESS = process.env.PAYMENT_TOKEN_ADDRESS;
  const TREASURY_ADDRESS = process.env.TREASURY_ADDRESS || deployer.address;

  // Helper to deploy OpenZeppelin preset ERC20 for local/testing
  async function ensureToken(address, name, symbol) {
    if (address && ethers.isAddress(address)) {
      console.log(`Using existing token for ${name}:`, address);
      return address;
    }
    console.log(`\n🪙 Deploying ${name} token (${symbol})...`);
    // Deploy local TestToken (OZ v5 no longer includes presets)
    const TestToken = await ethers.getContractFactory("TestToken");
    const token = await TestToken.deploy(name, symbol);
    await token.waitForDeployment();
    // Initial supply is minted to deployer in constructor
    console.log(`✅ ${name} deployed at:`, await token.getAddress());
    return await token.getAddress();
  }

  // 1) Tokens (base/payment)
  const baseTokenAddress = await ensureToken(BASE_TOKEN_ADDRESS, "Wishpers USD", "WUSD");
  const paymentTokenAddress = await ensureToken(PAYMENT_TOKEN_ADDRESS, "Wishpers Payment", "WPMT");

  // 2) Vault
  console.log("\n💰 Deploying Vault...");
  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(baseTokenAddress);
  await vault.waitForDeployment();
  console.log("✅ Vault:", await vault.getAddress());

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