const { ethers, network } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🔧 Deploying MockAssetAdapter and wiring to Vault...");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Network:", network.name);

  // Read existing deployment.json
  const deploymentPath = "deployment.json";
  if (!fs.existsSync(deploymentPath)) {
    throw new Error("deployment.json not found. Run core deploy first.");
  }
  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf-8"));

  const vaultAddress = deployment.contracts?.Vault;
  const baseToken = deployment.tokens?.baseToken;
  const tokens = [
    baseToken,
    deployment.tokens?.extra?.ATOM,
    deployment.tokens?.extra?.WETH,
  ].filter(Boolean);

  if (!vaultAddress || !baseToken) {
    throw new Error("Missing Vault or base token in deployment.json");
  }

  // Deploy MockAssetAdapter
  console.log("\n🧪 Deploying MockAssetAdapter...");
  const MockAssetAdapter = await ethers.getContractFactory("MockAssetAdapter");
  const adapter = await MockAssetAdapter.deploy(baseToken);
  await adapter.waitForDeployment();
  const adapterAddress = await adapter.getAddress();
  console.log("✅ MockAssetAdapter:", adapterAddress);

  // Wire adapter to Vault for each token
  console.log("\n🔗 Setting adapter on Vault for tracked tokens...");
  const Vault = await ethers.getContractFactory("Vault");
  const vault = Vault.attach(vaultAddress).connect(deployer);

  for (const token of tokens) {
    console.log(`- setAdapter(${token}) -> ${adapterAddress}`);
    const tx = await vault.setAdapter(token, adapterAddress);
    await tx.wait();
  }

  // Save adapter address into deployment.json
  deployment.adapters = deployment.adapters || {};
  deployment.adapters.MockAssetAdapter = adapterAddress;
  fs.writeFileSync(deploymentPath, JSON.stringify(deployment, null, 2));
  console.log("\n📁 Updated deployment.json with adapters.MockAssetAdapter");

  console.log("\n✅ Mock adapter deployment complete.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });