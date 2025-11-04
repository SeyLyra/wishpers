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
  const oracleAddr = deployment.adapters?.SomniaPriceOracleMock;

  if (!base || !atom || !weth || !vaultAddr) {
    throw new Error("Missing base/ATOM/WETH/Vault in deployment.json");
  }
  if (!oracleAddr) {
    console.warn("SomniaPriceOracleMock not found. Consider running deployPriceOracleMock.js first.");
  }

  // Deploy MockLendingPool
  const Pool = await ethers.getContractFactory("MockLendingPool");
  const pool = await Pool.deploy();
  await pool.waitForDeployment();
  console.log("MockLendingPool:", pool.target);

  // Seed reserves (arbitrary liquidity)
  await (await pool.configureReserve(base, 1_000_000n * 10n ** 6n)).wait();
  await (await pool.configureReserve(atom, 5_000_000n * 10n ** 6n)).wait();
  await (await pool.configureReserve(weth, 2_000n * 10n ** 18n)).wait();

  // Deploy aTokens for each asset
  const AToken = await ethers.getContractFactory("MockAToken");
  const aBase = await AToken.deploy("aBase", "aBASE");
  await aBase.waitForDeployment();
  const aAtom = await AToken.deploy("aATOM", "aATOM");
  await aAtom.waitForDeployment();
  const aWeth = await AToken.deploy("aWETH", "aWETH");
  await aWeth.waitForDeployment();
  console.log("Mock aTokens:", aBase.target, aAtom.target, aWeth.target);

  // Deploy SomniaLendingAdapter
  const Adapter = await ethers.getContractFactory("SomniaLendingAdapter");
  const adapter = await Adapter.deploy(pool.target, oracleAddr || ethers.ZeroAddress, base);
  await adapter.waitForDeployment();
  console.log("SomniaLendingAdapter:", adapter.target);

  // Register assets
  await (await adapter.registerAsset(base, aBase.target)).wait();
  await (await adapter.registerAsset(atom, aAtom.target)).wait();
  await (await adapter.registerAsset(weth, aWeth.target)).wait();

  // Set adapter in Vault for non-base assets (and optionally base)
  const Vault = await ethers.getContractAt("Vault", vaultAddr);
  await (await Vault.setAdapter(atom, adapter.target)).wait();
  await (await Vault.setAdapter(weth, adapter.target)).wait();
  // Optionally: set for base as well
  // await (await Vault.setAdapter(base, adapter.target)).wait();

  // Persist
  deployment.adapters = deployment.adapters || {};
  deployment.adapters.SomniaLendingAdapter = adapter.target;
  deployment.mocks = deployment.mocks || {};
  deployment.mocks.MockLendingPool = pool.target;
  deployment.mocks.aTokens = { base: aBase.target, ATOM: aAtom.target, WETH: aWeth.target };
  deployment.updatedAt = new Date().toISOString();
  fs.writeFileSync(deploymentPath, JSON.stringify(deployment, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});