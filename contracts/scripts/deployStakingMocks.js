const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const deploymentPath = path.join(__dirname, "../deployment.json");
  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const base = deployment.tokens?.baseToken || deployment.tokens?.base;
  const atom = deployment.tokens?.extra?.ATOM;
  const weth = deployment.tokens?.extra?.WETH;
  const vaultAddr = deployment.contracts?.Vault;

  if (!base || !atom || !weth || !vaultAddr) {
    throw new Error("Missing base/ATOM/WETH/Vault in deployment.json");
  }

  // Deploy MockYieldFarm
  const Farm = await ethers.getContractFactory("MockYieldFarm");
  const farm = await Farm.deploy();
  await farm.waitForDeployment();
  console.log("MockYieldFarm:", farm.target);

  // Use FaucetToken as reward token (e.g., base as reward) for simplicity
  const RewardToken = await ethers.getContractAt("FaucetToken", base);

  // Create simple pools: pid 1 for ATOM, pid 2 for WETH
  // Reward rate per second is small and arbitrary (scaled to token decimals)
  await (await farm.createPool(1, atom, base, 10n * 10n ** 6n)).wait();
  await (await farm.createPool(2, weth, base, 5n * 10n ** 18n)).wait();

  // Fund farm with reward tokens so harvest transfers succeed
  for (let i = 0; i < 10; i++) {
    await (await RewardToken.claimFor(farm.target)).wait();
  }

  // Deploy SomniaStakingAdapter
  const Adapter = await ethers.getContractFactory("SomniaStakingAdapter");
  const adapter = await Adapter.deploy(base);
  await adapter.waitForDeployment();
  console.log("SomniaStakingAdapter:", adapter.target);

  // Register yield farms for tokens
  await (await adapter.registerYieldFarm(atom, farm.target, 1)).wait();
  await (await adapter.registerYieldFarm(weth, farm.target, 2)).wait();

  // Set adapter in Vault
  const Vault = await ethers.getContractAt("Vault", vaultAddr);
  await (await Vault.setAdapter(atom, adapter.target)).wait();
  await (await Vault.setAdapter(weth, adapter.target)).wait();

  // Persist
  deployment.adapters = deployment.adapters || {};
  deployment.adapters.SomniaStakingAdapter = adapter.target;
  deployment.mocks = deployment.mocks || {};
  deployment.mocks.MockYieldFarm = farm.target;
  deployment.updatedAt = new Date().toISOString();
  fs.writeFileSync(deploymentPath, JSON.stringify(deployment, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});