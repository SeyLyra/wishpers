const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function codeExists(address) {
  const code = await ethers.provider.getCode(address);
  return code && code !== "0x";
}

async function main() {
  const deploymentPath = path.join(__dirname, "../deployment.json");
  if (!fs.existsSync(deploymentPath)) {
    throw new Error("deployment.json not found. Run core deploy first.");
  }
  const d = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));

  const tokens = {
    base: d.tokens?.baseToken || d.tokens?.base,
    ATOM: d.tokens?.extra?.ATOM,
    WETH: d.tokens?.extra?.WETH,
  };

  const { Vault } = d.contracts || {};
  const adapters = d.adapters || {};
  const mocks = d.mocks || {};

  console.log("Network:", d.network);
  console.log("Deployer:", d.deployer);

  // 1) Sanity check: contracts and adapters have code
  const addressesToCheck = [
    Vault,
    d.contracts?.MemoryContract,
    d.contracts?.Strategy,
    d.contracts?.AgentRegistry,
    d.contracts?.AgentFactory,
    d.contracts?.Marketplace,
    adapters.SomniaPriceOracleMock,
    adapters.SomniaLendingAdapter,
    adapters.SomniaStakingAdapter,
    mocks.MockLendingPool,
    mocks.MockYieldFarm,
    mocks.aTokens?.base,
    mocks.aTokens?.ATOM,
    mocks.aTokens?.WETH,
    tokens.base,
    tokens.ATOM,
    tokens.WETH,
  ].filter(Boolean);

  for (const addr of addressesToCheck) {
    const ok = await codeExists(addr);
    console.log(`Code @ ${addr}:`, ok ? "OK" : "MISSING");
  }

  // 2) Verify Vault adapter mappings for ATOM/WETH
  if (!Vault) throw new Error("Vault address missing");
  const vault = await ethers.getContractAt("Vault", Vault);
  const atomAdapter = await vault.adapters(tokens.ATOM);
  const wethAdapter = await vault.adapters(tokens.WETH);
  console.log("Vault.adapters[ATOM]:", atomAdapter);
  console.log("Vault.adapters[WETH]:", wethAdapter);

  // 3) Verify oracle prices
  if (adapters.SomniaPriceOracleMock) {
    const oracle = await ethers.getContractAt("SomniaPriceOracleMock", adapters.SomniaPriceOracleMock);
    const basePrice = await oracle.getAssetPrice(tokens.base);
    const atomPrice = await oracle.getAssetPrice(tokens.ATOM);
    const wethPrice = await oracle.getAssetPrice(tokens.WETH);
    console.log("Oracle prices (8d): base=", basePrice.toString(), "ATOM=", atomPrice.toString(), "WETH=", wethPrice.toString());
  } else {
    console.log("Oracle adapter missing in deployment.json");
  }

  // 4) Verify lending adapter asset registration
  if (adapters.SomniaLendingAdapter) {
    const lend = await ethers.getContractAt("SomniaLendingAdapter", adapters.SomniaLendingAdapter);
    const aBase = await lend.aTokens(tokens.base);
    const aAtom = await lend.aTokens(tokens.ATOM);
    const aWeth = await lend.aTokens(tokens.WETH);
    console.log("Lending aTokens:", {
      base: aBase,
      ATOM: aAtom,
      WETH: aWeth,
    });
    if (mocks.aTokens) {
      console.log("Expected aTokens:", mocks.aTokens);
    }
  } else {
    console.log("SomniaLendingAdapter missing in deployment.json");
  }

  // 5) Verify staking adapter registrations
  if (adapters.SomniaStakingAdapter) {
    const stake = await ethers.getContractAt("SomniaStakingAdapter", adapters.SomniaStakingAdapter);
    const farmATOM = await stake.yieldFarms(tokens.ATOM);
    const pidATOM = await stake.poolIds(tokens.ATOM);
    const farmWETH = await stake.yieldFarms(tokens.WETH);
    const pidWETH = await stake.poolIds(tokens.WETH);
    console.log("Staking yield farms:", {
      ATOM: { farm: farmATOM, pid: pidATOM.toString() },
      WETH: { farm: farmWETH, pid: pidWETH.toString() },
    });
  } else {
    console.log("SomniaStakingAdapter missing in deployment.json");
  }

  console.log("\nVerification complete.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});