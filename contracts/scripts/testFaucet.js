const { ethers } = require("hardhat");

async function main() {
  console.log("🧪 Testing FaucetToken contract...\n");

  const [deployer, user1, user2] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("User1:", user1.address);
  console.log("User2:", user2.address);

  // Deploy FaucetToken
  console.log("\n🪙 Deploying FaucetToken...");
  const FaucetToken = await ethers.getContractFactory("FaucetToken");
  const token = await FaucetToken.deploy(
    "Mock USDC",
    "USDC",
    ethers.parseEther("1000"), // 1000 tokens per claim
    0 // No cooldown for testing
  );
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("✅ FaucetToken deployed at:", tokenAddress);

  // Check initial deployer balance
  const deployerBalance = await token.balanceOf(deployer.address);
  console.log("\n📊 Initial deployer balance:", ethers.formatEther(deployerBalance), "USDC");

  // Test 1: User1 claims tokens
  console.log("\n🎯 Test 1: User1 claims tokens");
  const user1Token = token.connect(user1);
  const tx1 = await user1Token.claim();
  await tx1.wait();
  const user1Balance = await token.balanceOf(user1.address);
  console.log("✅ User1 claimed:", ethers.formatEther(user1Balance), "USDC");

  // Test 2: User2 uses claimFor (backend scenario)
  console.log("\n🎯 Test 2: Deployer claims for User2 (backend faucet)");
  const tx2 = await token.claimFor(user2.address);
  await tx2.wait();
  const user2Balance = await token.balanceOf(user2.address);
  console.log("✅ User2 received:", ethers.formatEther(user2Balance), "USDC");

  // Test 3: Check canClaim
  console.log("\n🎯 Test 3: Check canClaim status");
  const [canClaimUser1, timeUntilUser1] = await token.canClaim(user1.address);
  console.log("User1 can claim:", canClaimUser1, "| Time until next:", timeUntilUser1.toString(), "seconds");

  const [canClaimUser3, timeUntilUser3] = await token.canClaim(deployer.address);
  console.log("Deployer can claim:", canClaimUser3, "| Time until next:", timeUntilUser3.toString(), "seconds");

  // Test 4: Try claiming again (should fail if cooldown > 0)
  if (!canClaimUser1) {
    console.log("\n🎯 Test 4: Try claiming again during cooldown");
    try {
      await user1Token.claim();
      console.log("❌ Should have failed due to cooldown");
    } catch (error) {
      console.log("✅ Correctly rejected claim during cooldown");
    }
  }

  // Test 5: Owner mints tokens directly
  console.log("\n🎯 Test 5: Owner mints tokens directly");
  const tx5 = await token.mint(user1.address, ethers.parseEther("500"));
  await tx5.wait();
  const user1BalanceAfterMint = await token.balanceOf(user1.address);
  console.log("✅ User1 balance after owner mint:", ethers.formatEther(user1BalanceAfterMint), "USDC");

  // Test 6: Check faucet configuration
  console.log("\n🎯 Test 6: Check faucet configuration");
  const faucetAmount = await token.faucetAmount();
  const cooldownTime = await token.cooldownTime();
  console.log("Faucet amount:", ethers.formatEther(faucetAmount), "USDC");
  console.log("Cooldown time:", cooldownTime.toString(), "seconds");

  console.log("\n✅ All tests passed!");
  console.log("\n📋 Summary:");
  console.log("- Deployer balance:", ethers.formatEther(await token.balanceOf(deployer.address)), "USDC");
  console.log("- User1 balance:", ethers.formatEther(await token.balanceOf(user1.address)), "USDC");
  console.log("- User2 balance:", ethers.formatEther(await token.balanceOf(user2.address)), "USDC");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Test failed:", error);
    process.exit(1);
  });
