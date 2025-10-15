const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying Immortal AI Souls contracts...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);
  console.log("💰 Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  // Deploy the main contract
  const ImmortalSouls = await ethers.getContractFactory("ImmortalSouls");
  console.log("🏗️  Deploying ImmortalSouls...");
  
  const immortalSouls = await ImmortalSouls.deploy();
  await immortalSouls.waitForDeployment();
  
  const contractAddress = await immortalSouls.getAddress();
  console.log("✅ ImmortalSouls deployed to:", contractAddress);

  // Get deployment info
  const deployment = await immortalSouls.deploymentTransaction();
  console.log("📊 Deployment transaction hash:", deployment.hash);
  console.log("⛽ Gas used:", deployment.gasLimit.toString());

  // Verify deployment
  console.log("🔍 Verifying deployment...");
  const code = await deployer.provider.getCode(contractAddress);
  if (code === "0x") {
    console.log("❌ Contract deployment failed - no code at address");
    return;
  }
  console.log("✅ Contract deployment verified successfully");

  // Initialize contract with some basic upgrades
  console.log("🔧 Initializing contract with basic upgrades...");
  
  try {
    // Add some basic upgrades
    const basicUpgrade = await immortalSouls.addUpgrade(
      1, // upgradeId
      "Basic Enhancement", // name
      "Basic soul enhancement", // description
      ethers.parseEther("0.1"), // cost
      [1] // requirements (level 1)
    );
    await basicUpgrade.wait();
    console.log("✅ Basic upgrade added");

    const advancedUpgrade = await immortalSouls.addUpgrade(
      2, // upgradeId
      "Advanced Enhancement", // name
      "Advanced soul enhancement", // description
      ethers.parseEther("0.5"), // cost
      [5] // requirements (level 5)
    );
    await advancedUpgrade.wait();
    console.log("✅ Advanced upgrade added");

    const legendaryUpgrade = await immortalSouls.addUpgrade(
      3, // upgradeId
      "Legendary Enhancement", // name
      "Legendary soul enhancement", // description
      ethers.parseEther("1.0"), // cost
      [10] // requirements (level 10)
    );
    await legendaryUpgrade.wait();
    console.log("✅ Legendary upgrade added");

  } catch (error) {
    console.log("⚠️  Warning: Could not add upgrades:", error.message);
  }

  // Print deployment summary
  console.log("\n🎉 Deployment Summary:");
  console.log("=========================");
  console.log("Contract: ImmortalSouls");
  console.log("Address:", contractAddress);
  console.log("Network:", network.name);
  console.log("Deployer:", deployer.address);
  console.log("Transaction:", deployment.hash);
  
  // Save deployment info to file
  const deploymentInfo = {
    contract: "ImmortalSouls",
    address: contractAddress,
    network: network.name,
    deployer: deployer.address,
    transaction: deployment.hash,
    timestamp: new Date().toISOString(),
    upgrades: [
      { id: 1, name: "Basic Enhancement", cost: "0.1 SEI", requirement: "Level 1" },
      { id: 2, name: "Advanced Enhancement", cost: "0.5 SEI", requirement: "Level 5" },
      { id: 3, name: "Legendary Enhancement", cost: "1.0 SEI", requirement: "Level 10" }
    ]
  };

  const fs = require("fs");
  fs.writeFileSync(
    `deployment-${network.name}-${Date.now()}.json`,
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("💾 Deployment info saved to file");

  // Instructions for next steps
  console.log("\n📋 Next Steps:");
  console.log("1. Update your backend .env file with the contract address");
  console.log("2. Verify the contract on Sei Scan (if available)");
  console.log("3. Test the contract functions");
  console.log("4. Update your frontend with the new contract address");
  
  console.log("\n🔗 Contract Address for Backend:");
  console.log(`SEI_CONTRACT_ADDRESS=${contractAddress}`);
}

// Handle errors
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }); 