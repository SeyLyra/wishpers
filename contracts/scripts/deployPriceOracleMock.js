const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const deploymentPath = path.join(__dirname, "../deployment.json");
  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const Oracle = await ethers.getContractFactory("SomniaPriceOracleMock");
  const oracle = await Oracle.deploy();
  await oracle.waitForDeployment();
  console.log("SomniaPriceOracleMock:", oracle.target);

  // Set example prices with 8 decimals (1 USDC = 1.00, ATOM = 1.20, WETH = 3500)
  const base = deployment.tokens?.baseToken || deployment.tokens?.base;
  const atom = deployment.tokens?.extra?.ATOM;
  const weth = deployment.tokens?.extra?.WETH;

  if (!base || !atom || !weth) {
    console.warn("Missing token addresses in deployment.json. Skipping price setup.");
  } else {
    const tx1 = await oracle.setAssetPrice(base, 100_000_000n); // 1.00
    await tx1.wait();
    const tx2 = await oracle.setAssetPrice(atom, 120_000_000n); // 1.20
    await tx2.wait();
    const tx3 = await oracle.setAssetPrice(weth, 3500_000_000n); // 3500
    await tx3.wait();
    console.log("Prices set for base/ATOM/WETH");
  }

  deployment.adapters = deployment.adapters || {};
  deployment.adapters.SomniaPriceOracleMock = oracle.target;
  deployment.updatedAt = new Date().toISOString();
  fs.writeFileSync(deploymentPath, JSON.stringify(deployment, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});