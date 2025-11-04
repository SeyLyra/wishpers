const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const addr = deployer.address;
  const bal = await ethers.provider.getBalance(addr);
  console.log("Deployer:", addr);
  console.log("Balance (wei):", bal.toString());
  console.log("Balance (STT):", ethers.formatEther(bal));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});