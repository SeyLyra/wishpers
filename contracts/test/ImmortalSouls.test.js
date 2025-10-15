const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ImmortalSouls", function () {
  let ImmortalSouls;
  let immortalSouls;
  let owner;
  let user1;
  let user2;
  let addrs;

  beforeEach(async function () {
    // Get signers
    [owner, user1, user2, ...addrs] = await ethers.getSigners();

    // Deploy contract
    ImmortalSouls = await ethers.getContractFactory("ImmortalSouls");
    immortalSouls = await ImmortalSouls.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await immortalSouls.owner()).to.equal(owner.address);
    });

    it("Should have correct name and symbol", async function () {
      expect(await immortalSouls.name()).to.equal("Immortal AI Souls");
      expect(await immortalSouls.symbol()).to.equal("SOUL");
    });
  });

  describe("Soul Minting", function () {
    it("Should allow owner to mint souls", async function () {
      const soulName = "Test Soul";
      const soulDescription = "A test soul";
      const imageUri = "https://example.com/image.jpg";
      const memoryCid = "QmTestMemoryCID";
      const traits = [80, 70, 90]; // Intelligence, Creativity, Wisdom

      await immortalSouls.mintSoul(
        user1.address,
        soulName,
        soulDescription,
        imageUri,
        memoryCid,
        traits
      );

      expect(await immortalSouls.ownerOf(1)).to.equal(user1.address);
      
      const metadata = await immortalSouls.getSoulMetadata(1);
      expect(metadata.name).to.equal(soulName);
      expect(metadata.memoryCid).to.equal(memoryCid);
      expect(metadata.level).to.equal(1);
      expect(metadata.experience).to.equal(0);
    });

    it("Should not allow non-owner to mint souls", async function () {
      const soulName = "Test Soul";
      const soulDescription = "A test soul";
      const imageUri = "https://example.com/image.jpg";
      const memoryCid = "QmTestMemoryCID";
      const traits = [80, 70, 90];

      await expect(
        immortalSouls.connect(user1).mintSoul(
          user1.address,
          soulName,
          soulDescription,
          imageUri,
          memoryCid,
          traits
        )
      ).to.be.revertedWithCustomError(immortalSouls, "OwnableUnauthorizedAccount");
    });

    it("Should emit SoulMinted event", async function () {
      const soulName = "Test Soul";
      const soulDescription = "A test soul";
      const imageUri = "https://example.com/image.jpg";
      const memoryCid = "QmTestMemoryCID";
      const traits = [80, 70, 90];

      await expect(
        immortalSouls.mintSoul(
          user1.address,
          soulName,
          soulDescription,
          imageUri,
          memoryCid,
          traits
        )
      ).to.emit(immortalSouls, "SoulMinted")
        .withArgs(user1.address, 1, memoryCid);
    });
  });

  describe("Soul Merging", function () {
    beforeEach(async function () {
      // Mint two souls first
      await immortalSouls.mintSoul(
        user1.address,
        "Soul 1",
        "First soul",
        "https://example.com/soul1.jpg",
        "QmSoul1Memory",
        [80, 70, 90]
      );

      await immortalSouls.mintSoul(
        user1.address,
        "Soul 2",
        "Second soul",
        "https://example.com/soul2.jpg",
        "QmSoul2Memory",
        [85, 75, 95]
      );
    });

    it("Should allow soul owner to merge souls", async function () {
      const soulIds = [1, 2];
      const mergedName = "Merged Soul";
      const mergedDescription = "A merged soul";
      const mergedMemoryCid = "QmMergedMemory";

      await immortalSouls.connect(user1).mergeSouls(
        soulIds,
        mergedName,
        mergedDescription,
        mergedMemoryCid
      );

      // Check that new soul was created
      expect(await immortalSouls.ownerOf(3)).to.equal(user1.address);
      
      const metadata = await immortalSouls.getSoulMetadata(3);
      expect(metadata.name).to.equal(mergedName);
      expect(metadata.memoryCid).to.equal(mergedMemoryCid);
      
      // Check that original souls are burned
      await expect(immortalSouls.ownerOf(1)).to.be.revertedWith("ERC721: invalid token ID");
      await expect(immortalSouls.ownerOf(2)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("Should not allow non-owner to merge souls", async function () {
      const soulIds = [1, 2];
      const mergedName = "Merged Soul";
      const mergedDescription = "A merged soul";
      const mergedMemoryCid = "QmMergedMemory";

      await expect(
        immortalSouls.connect(user2).mergeSouls(
          soulIds,
          mergedName,
          mergedDescription,
          mergedMemoryCid
        )
      ).to.be.revertedWith("Not owner of all souls");
    });

    it("Should emit SoulsMerged event", async function () {
      const soulIds = [1, 2];
      const mergedName = "Merged Soul";
      const mergedDescription = "A merged soul";
      const mergedMemoryCid = "QmMergedMemory";

      await expect(
        immortalSouls.connect(user1).mergeSouls(
          soulIds,
          mergedName,
          mergedDescription,
          mergedMemoryCid
        )
      ).to.emit(immortalSouls, "SoulsMerged")
        .withArgs(user1.address, 3, soulIds);
    });
  });

  describe("Inheritance System", function () {
    beforeEach(async function () {
      // Mint a soul
      await immortalSouls.mintSoul(
        user1.address,
        "Test Soul",
        "A test soul",
        "https://example.com/image.jpg",
        "QmTestMemory",
        [80, 70, 90]
      );
    });

    it("Should allow soul owner to set inheritance", async function () {
      const heir = user2.address;
      const triggerTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

      await immortalSouls.connect(user1).setInheritance(1, heir, triggerTime);

      const inheritance = await immortalSouls.inheritances(1);
      expect(inheritance.heir).to.equal(heir);
      expect(inheritance.triggerTime).to.equal(triggerTime);
      expect(inheritance.isActive).to.be.true;
    });

    it("Should emit InheritanceSet event", async function () {
      const heir = user2.address;
      const triggerTime = Math.floor(Date.now() / 1000) + 3600;

      await expect(
        immortalSouls.connect(user1).setInheritance(1, heir, triggerTime)
      ).to.emit(immortalSouls, "InheritanceSet")
        .withArgs(1, heir, triggerTime);
    });
  });

  describe("Upgrades", function () {
    it("Should allow owner to add upgrades", async function () {
      const upgradeId = 1;
      const name = "Basic Enhancement";
      const description = "Basic soul enhancement";
      const cost = ethers.parseEther("0.1");
      const requirements = [1];

      await immortalSouls.addUpgrade(upgradeId, name, description, cost, requirements);

      const upgrade = await immortalSouls.upgrades(upgradeId);
      expect(upgrade.name).to.equal(name);
      expect(upgrade.description).to.equal(description);
      expect(upgrade.cost).to.equal(cost);
      expect(upgrade.isActive).to.be.true;
    });

    it("Should not allow non-owner to add upgrades", async function () {
      const upgradeId = 1;
      const name = "Basic Enhancement";
      const description = "Basic soul enhancement";
      const cost = ethers.parseEther("0.1");
      const requirements = [1];

      await expect(
        immortalSouls.connect(user1).addUpgrade(upgradeId, name, description, cost, requirements)
      ).to.be.revertedWithCustomError(immortalSouls, "OwnableUnauthorizedAccount");
    });
  });

  describe("Experience and Leveling", function () {
    beforeEach(async function () {
      // Mint a soul
      await immortalSouls.mintSoul(
        user1.address,
        "Test Soul",
        "A test soul",
        "https://example.com/image.jpg",
        "QmTestMemory",
        [80, 70, 90]
      );
    });

    it("Should allow owner to add experience", async function () {
      await immortalSouls.addExperience(1, 100);
      
      const metadata = await immortalSouls.getSoulMetadata(1);
      expect(metadata.experience).to.equal(100);
      expect(metadata.level).to.equal(2); // Level 2 after 100 experience
    });

    it("Should emit SoulLevelUp event when leveling up", async function () {
      await expect(immortalSouls.addExperience(1, 100))
        .to.emit(immortalSouls, "SoulLevelUp")
        .withArgs(1, 2, 100);
    });

    it("Should not allow non-owner to add experience", async function () {
      await expect(
        immortalSouls.connect(user1).addExperience(1, 100)
      ).to.be.revertedWithCustomError(immortalSouls, "OwnableUnauthorizedAccount");
    });
  });

  describe("Pausing", function () {
    it("Should allow owner to pause and unpause", async function () {
      await immortalSouls.pause();
      expect(await immortalSouls.paused()).to.be.true;

      await immortalSouls.unpause();
      expect(await immortalSouls.paused()).to.be.false;
    });

    it("Should not allow non-owner to pause", async function () {
      await expect(
        immortalSouls.connect(user1).pause()
      ).to.be.revertedWithCustomError(immortalSouls, "OwnableUnauthorizedAccount");
    });
  });
}); 