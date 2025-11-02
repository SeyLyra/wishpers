const { ethers, network } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🤖 Creating an agent via AgentFactory...");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Network:", network.name);

  // Read deployment.json written by scripts/deploy.js
  const deploymentPath = "deployment.json";
  if (!fs.existsSync(deploymentPath)) {
    throw new Error(
      "deployment.json not found. Run `npx hardhat run --network <net> scripts/deploy.js` first."
    );
  }
  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf-8"));

  const vaultAddress = deployment.contracts?.Vault;
  const memoryAddress = deployment.contracts?.MemoryContract;
  const factoryAddress = deployment.contracts?.AgentFactory;
  const baseToken = deployment.tokens?.baseToken;
  const paymentToken = deployment.tokens?.paymentToken;

  if (!vaultAddress || !memoryAddress || !factoryAddress || !baseToken || !paymentToken) {
    throw new Error("Missing contract addresses in deployment.json");
  }

  // Connect to contracts
  const Vault = await ethers.getContractFactory("Vault");
  const vault = Vault.attach(vaultAddress);

  const MemoryContract = await ethers.getContractFactory("MemoryContract");
  const memory = MemoryContract.attach(memoryAddress);

  const AgentFactory = await ethers.getContractFactory("AgentFactory");
  const factory = AgentFactory.attach(factoryAddress);

  const AgentRegistry = await ethers.getContractFactory("AgentRegistry");
  const registry = AgentRegistry.attach(deployment.contracts.AgentRegistry);

  // Metadata URI can be overridden by env var
  const agentName = process.env.AGENT_NAME || "Wishpers Agent #1";
  const metadataURI =
    process.env.AGENT_METADATA_URI || "ipfs://bafkreiagentmetadataexample";

  console.log("\n🏭 Deploying agent proxy via factory...");
  const tx = await factory.deployAgent(
    deployer.address,
    agentName,
    metadataURI,
    vaultAddress,
    memoryAddress
  );
  await tx.wait();

  // Resolve agent via registry ownership listing (more reliable across providers)
  const ownerAgents = await registry.getOwnerAgents(deployer.address);
  const agentAddress = ownerAgents && ownerAgents.length > 0 ? ownerAgents[ownerAgents.length - 1] : (await inferAgentFromRegistry(deployment));
  if (!agentAddress) {
    throw new Error("Agent address not found in transaction logs or registry");
  }
  console.log("✅ Agent deployed:", agentAddress);

  // Grant AGENT_ROLE in Vault and MemoryContract
  console.log("\n🔐 Granting AGENT_ROLE to agent in Vault and MemoryContract...");
  await (await vault.grantAgentRole(agentAddress)).wait();
  await (await memory.grantAgentRole(agentAddress)).wait();
  console.log("✅ Roles granted");

  // Prefill vault balances for demo (depositor = deployer)
  console.log("\n💰 Prefilling Vault with base/payment tokens for demo...");
  const erc20 = await ethers.getContractFactory("TestToken");
  const base = erc20.attach(baseToken);
  const pay = erc20.attach(paymentToken);

  const amountBase = ethers.parseEther("1000");
  const amountPay = ethers.parseEther("1000");

  // Approve Vault to pull tokens
  await (await base.approve(vaultAddress, amountBase)).wait();
  await (await pay.approve(vaultAddress, amountPay)).wait();

  // Deposit will auto-track token if caller has MANAGER_ROLE (deployer does)
  await (await vault.deposit(baseToken, amountBase)).wait();
  await (await vault.deposit(paymentToken, amountPay)).wait();
  console.log("✅ Deposited base/payment tokens into Vault");

  // Allow tokens for agent trading limits (optional demo setup)
  const AgentLogic = await ethers.getContractFactory("AgentLogic");
  const agent = AgentLogic.attach(agentAddress);

  console.log("\n⚙️ Setting allowed tokens and position limits on agent...");
  const maxPos = ethers.parseEther("1000000");
  await (await agent.setAllowedToken(paymentToken, true, maxPos)).wait();
  await (await agent.setAllowedToken(baseToken, true, maxPos)).wait();
  console.log("✅ Allowed tokens configured");

  // Persist agent address in deployment.json for client/server usage
  deployment.contracts.Agent = agentAddress;
  fs.writeFileSync(deploymentPath, JSON.stringify(deployment, null, 2));
  console.log("\n📁 Updated deployment.json with Agent address");

  console.log("\n🎉 Agent setup complete.");
  console.log("Next:");
  console.log("- You can trigger trades via AgentLogic.buy/sell (requires adapters for real swaps).");
  console.log("- Start server/client; point them at addresses in deployment.json.");
}

// Fallback: infer last agent from registry if event parsing fails
async function inferAgentFromRegistry(deployment) {
  try {
    const AgentRegistry = await ethers.getContractFactory("AgentRegistry");
    const registry = AgentRegistry.attach(deployment.contracts.AgentRegistry);
    const total = await registry.getTotalAgents();
    if (total && Number(total) > 0) {
      return await registry.getAgentByVersion(total);
    }
  } catch (_) {}
  return null;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Agent creation failed:", error);
    process.exit(1);
  });