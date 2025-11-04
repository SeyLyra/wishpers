const { ethers } = require("hardhat");

async function main() {
  const [deployer, seller, buyer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Seller:", seller.address);
  console.log("Buyer:", buyer.address);

  // Load deployment.json
  const fs = require('fs');
  const path = require('path');
  const dep = JSON.parse(fs.readFileSync(path.join(__dirname, '../deployment.json'), 'utf8'));

  const marketplaceAddr = dep.contracts.Marketplace;
  const vaultAddr = dep.contracts.Vault;
  const baseTokenAddr = dep.tokens.baseToken; // Mock USDT
  const atomAddr = dep.tokens.extra.ATOM;
  const wethAddr = dep.tokens.extra.WETH;

  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = Marketplace.attach(marketplaceAddr);

  const TestToken = await ethers.getContractFactory("TestToken");
  const usdt = TestToken.attach(baseTokenAddr);
  const atom = TestToken.attach(atomAddr);
  const weth = TestToken.attach(wethAddr);

  // Distribute mock tokens from deployer to seller/buyer
  console.log("\n🔄 Distributing mock tokens...");
  const amount = ethers.parseUnits("10000", 18);
  await (await usdt.transfer(seller.address, amount)).wait();
  await (await usdt.transfer(buyer.address, amount)).wait();
  await (await atom.transfer(seller.address, amount)).wait();
  await (await atom.transfer(buyer.address, amount)).wait();
  await (await weth.transfer(seller.address, amount)).wait();
  await (await weth.transfer(buyer.address, amount)).wait();
  console.log("✅ Distributed 10k USDT/ATOM/WETH to seller and buyer");

  // Grant seller the LISTER_ROLE
  const LISTER_ROLE = await marketplace.LISTER_ROLE();
  console.log("\n🔐 Granting LISTER_ROLE to seller...");
  await (await marketplace.connect(deployer).grantRole(LISTER_ROLE, seller.address)).wait();
  console.log("✅ LISTER_ROLE granted");

  // Seller lists a native STT item
  console.log("\n🛍️ Listing native STT item...");
  const price = ethers.parseEther("0.05");
  const txList = await marketplace.connect(seller).listItem(
    1,
    "Starter Upgrade",
    "Boosts starting capital by 10%",
    "ipfs://bafy...",
    ethers.ZeroAddress, // native STT
    price
  );
  const receiptList = await txList.wait();
  const listedEvent = receiptList.logs.find(l => true); // simplistic log pick
  console.log("✅ Item listed. Tx:", txList.hash);
  // Using itemCounter as id
  const itemId = (await marketplace.itemCounter()).toString();

  // Buyer purchases the item with native STT
  console.log("\n💳 Purchasing item with native STT...");
  const txBuy = await marketplace.connect(buyer).purchaseItem(itemId, { value: price });
  await txBuy.wait();
  console.log("✅ Purchased. Tx:", txBuy.hash);

  console.log("\n🎯 Seed complete: marketplace listing and purchase validated on localhost.");
}

main().catch((e) => {
  console.error("Seed failed:", e);
  process.exit(1);
});