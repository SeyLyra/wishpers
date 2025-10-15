// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title ImmortalSouls
 * @dev Main contract for Immortal AI Souls on Chain
 * 
 * Features:
 * - Soul NFT minting with IPFS metadata
 * - Soul merging to create hybrid souls
 * - Inheritance system with time-based triggers
 * - Trading and marketplace integration
 * - Upgrade system for soul enhancement
 */
contract ImmortalSouls is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    // Soul metadata structure
    struct SoulMetadata {
        string name;
        string description;
        string imageUri;
        string memoryCid;        // IPFS CID for soul memory
        uint256 level;
        uint256 experience;
        uint256[] traits;        // Personality, skills, etc.
        uint256 createdAt;
        address creator;
        bool isActive;
    }
    
    // Inheritance structure
    struct Inheritance {
        address heir;
        uint256 triggerTime;
        bool isActive;
        uint256 soulId;
    }
    
    // Trading structure
    struct Trade {
        uint256 soulId;
        address token;
        uint256 amount;
        bool isBuy;
        uint256 timestamp;
        address trader;
    }
    
    // Upgrade structure
    struct Upgrade {
        uint256 upgradeId;
        string name;
        string description;
        uint256 cost;
        bool isActive;
        uint256[] requirements;
    }
    
    // State variables
    mapping(uint256 => SoulMetadata) public soulMetadata;
    mapping(uint256 => Inheritance) public inheritances;
    mapping(uint256 => Trade[]) public soulTrades;
    mapping(uint256 => uint256[]) public soulUpgrades;
    mapping(address => uint256[]) public userSouls;
    mapping(uint256 => Upgrade) public upgrades;
    
    // Events
    event SoulMinted(address indexed to, uint256 indexed tokenId, string memoryCid);
    event SoulsMerged(address indexed to, uint256 indexed newSoulId, uint256[] mergedSoulIds);
    event InheritanceSet(uint256 indexed soulId, address indexed heir, uint256 triggerTime);
    event InheritanceExecuted(uint256 indexed soulId, address indexed heir, uint256 timestamp);
    event TradeExecuted(uint256 indexed soulId, address indexed token, uint256 amount, bool isBuy);
    event UpgradePurchased(uint256 indexed soulId, uint256 indexed upgradeId);
    event SoulLevelUp(uint256 indexed soulId, uint256 newLevel, uint256 experience);
    
    // Modifiers
    modifier onlySoulOwner(uint256 soulId) {
        require(ownerOf(soulId) == msg.sender, "Not soul owner");
        _;
    }
    
    modifier soulExists(uint256 soulId) {
        require(_exists(soulId), "Soul does not exist");
        _;
    }
    
    modifier soulActive(uint256 soulId) {
        require(soulMetadata[soulId].isActive, "Soul is not active");
        _;
    }
    
    constructor() ERC721("Immortal AI Souls", "SOUL") {
        _tokenIds.increment(); // Start from token ID 1
    }
    
    /**
     * @dev Mint a new soul NFT
     * @param to Address to mint the soul to
     * @param name Soul name
     * @param description Soul description
     * @param imageUri Soul image URI
     * @param memoryCid IPFS CID for soul memory
     * @param traits Array of soul traits
     */
    function mintSoul(
        address to,
        string memory name,
        string memory description,
        string memory imageUri,
        string memory memoryCid,
        uint256[] memory traits
    ) external onlyOwner whenNotPaused returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(memoryCid).length > 0, "Memory CID cannot be empty");
        
        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();
        
        _safeMint(to, newTokenId);
        
        // Set soul metadata
        soulMetadata[newTokenId] = SoulMetadata({
            name: name,
            description: description,
            imageUri: imageUri,
            memoryCid: memoryCid,
            level: 1,
            experience: 0,
            traits: traits,
            createdAt: block.timestamp,
            creator: to,
            isActive: true
        });
        
        // Add to user's soul collection
        userSouls[to].push(newTokenId);
        
        emit SoulMinted(to, newTokenId, memoryCid);
        
        return newTokenId;
    }
    
    /**
     * @dev Merge multiple souls into a new hybrid soul
     * @param soulIds Array of soul IDs to merge
     * @param name Name for the new merged soul
     * @param description Description for the new merged soul
     * @param memoryCid IPFS CID for merged soul memory
     */
    function mergeSouls(
        uint256[] memory soulIds,
        string memory name,
        string memory description,
        string memory memoryCid
    ) external whenNotPaused returns (uint256) {
        require(soulIds.length >= 2, "Need at least 2 souls to merge");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(memoryCid).length > 0, "Memory CID cannot be empty");
        
        // Verify ownership of all souls
        for (uint256 i = 0; i < soulIds.length; i++) {
            require(ownerOf(soulIds[i]) == msg.sender, "Not owner of all souls");
            require(soulMetadata[soulIds[i]].isActive, "All souls must be active");
        }
        
        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();
        
        _safeMint(msg.sender, newTokenId);
        
        // Calculate merged traits (average of all souls)
        uint256[] memory mergedTraits = new uint256[](soulMetadata[soulIds[0]].traits.length);
        uint256 maxLevel = 0;
        
        for (uint256 i = 0; i < soulIds.length; i++) {
            SoulMetadata memory soul = soulMetadata[soulIds[i]];
            if (soul.level > maxLevel) maxLevel = soul.level;
            
            for (uint256 j = 0; j < soul.traits.length; j++) {
                mergedTraits[j] += soul.traits[j];
            }
        }
        
        // Average the traits
        for (uint256 i = 0; i < mergedTraits.length; i++) {
            mergedTraits[i] = mergedTraits[i] / soulIds.length;
        }
        
        // Set merged soul metadata
        soulMetadata[newTokenId] = SoulMetadata({
            name: name,
            description: description,
            imageUri: soulMetadata[soulIds[0]].imageUri, // Use first soul's image
            memoryCid: memoryCid,
            level: maxLevel,
            experience: 0,
            traits: mergedTraits,
            createdAt: block.timestamp,
            creator: msg.sender,
            isActive: true
        });
        
        // Deactivate original souls
        for (uint256 i = 0; i < soulIds.length; i++) {
            soulMetadata[soulIds[i]].isActive = false;
            _burn(soulIds[i]);
        }
        
        // Add to user's soul collection
        userSouls[msg.sender].push(newTokenId);
        
        emit SoulsMerged(msg.sender, newTokenId, soulIds);
        
        return newTokenId;
    }
    
    /**
     * @dev Set inheritance for a soul
     * @param soulId Soul ID to set inheritance for
     * @param heir Address of the heir
     * @param triggerTime Time when inheritance can be claimed
     */
    function setInheritance(
        uint256 soulId,
        address heir,
        uint256 triggerTime
    ) external onlySoulOwner(soulId) soulExists(soulId) soulActive(soulId) {
        require(heir != address(0), "Invalid heir address");
        require(triggerTime > block.timestamp, "Trigger time must be in future");
        
        inheritances[soulId] = Inheritance({
            heir: heir,
            triggerTime: triggerTime,
            isActive: true,
            soulId: soulId
        });
        
        emit InheritanceSet(soulId, heir, triggerTime);
    }
    
    /**
     * @dev Execute inheritance when conditions are met
     * @param soulId Soul ID to inherit
     */
    function executeInheritance(uint256 soulId) external whenNotPaused {
        Inheritance memory inheritance = inheritances[soulId];
        require(inheritance.isActive, "Inheritance not set");
        require(inheritance.heir == msg.sender, "Not the heir");
        require(block.timestamp >= inheritance.triggerTime, "Inheritance not yet available");
        
        address currentOwner = ownerOf(soulId);
        require(currentOwner != address(0), "Soul does not exist");
        
        // Transfer soul to heir
        _transfer(currentOwner, msg.sender, soulId);
        
        // Update user soul collections
        _removeFromUserSouls(currentOwner, soulId);
        userSouls[msg.sender].push(soulId);
        
        // Deactivate inheritance
        inheritances[soulId].isActive = false;
        
        emit InheritanceExecuted(soulId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Execute a trade for a soul
     * @param soulId Soul ID to trade
     * @param token Token address for the trade
     * @param amount Amount of tokens
     * @param isBuy Whether this is a buy or sell
     */
    function executeTrade(
        uint256 soulId,
        address token,
        uint256 amount,
        bool isBuy
    ) external onlySoulOwner(soulId) soulExists(soulId) soulActive(soulId) {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be positive");
        
        Trade memory trade = Trade({
            soulId: soulId,
            token: token,
            amount: amount,
            isBuy: isBuy,
            timestamp: block.timestamp,
            trader: msg.sender
        });
        
        soulTrades[soulId].push(trade);
        
        emit TradeExecuted(soulId, token, amount, isBuy);
    }
    
    /**
     * @dev Purchase an upgrade for a soul
     * @param soulId Soul ID to upgrade
     * @param upgradeId Upgrade ID to purchase
     */
    function purchaseUpgrade(
        uint256 soulId,
        uint256 upgradeId
    ) external onlySoulOwner(soulId) soulExists(soulId) soulActive(soulId) {
        Upgrade memory upgrade = upgrades[upgradeId];
        require(upgrade.isActive, "Upgrade not available");
        require(upgrade.cost > 0, "Upgrade has no cost");
        
        // Check if soul meets requirements
        for (uint256 i = 0; i < upgrade.requirements.length; i++) {
            require(soulMetadata[soulId].level >= upgrade.requirements[i], "Requirements not met");
        }
        
        // Add upgrade to soul
        soulUpgrades[soulId].push(upgradeId);
        
        emit UpgradePurchased(soulId, upgradeId);
    }
    
    /**
     * @dev Add experience to a soul and level up if possible
     * @param soulId Soul ID to add experience to
     * @param experience Amount of experience to add
     */
    function addExperience(
        uint256 soulId,
        uint256 experience
    ) external onlyOwner {
        require(_exists(soulId), "Soul does not exist");
        
        soulMetadata[soulId].experience += experience;
        
        // Check for level up (every 100 experience = 1 level)
        uint256 newLevel = (soulMetadata[soulId].experience / 100) + 1;
        if (newLevel > soulMetadata[soulId].level) {
            soulMetadata[soulId].level = newLevel;
            emit SoulLevelUp(soulId, newLevel, soulMetadata[soulId].experience);
        }
    }
    
    /**
     * @dev Get soul metadata
     * @param soulId Soul ID
     * @return Soul metadata
     */
    function getSoulMetadata(uint256 soulId) external view returns (SoulMetadata memory) {
        require(_exists(soulId), "Soul does not exist");
        return soulMetadata[soulId];
    }
    
    /**
     * @dev Get user's souls
     * @param user User address
     * @return Array of soul IDs
     */
    function getUserSouls(address user) external view returns (uint256[] memory) {
        return userSouls[user];
    }
    
    /**
     * @dev Get soul trades
     * @param soulId Soul ID
     * @return Array of trades
     */
    function getSoulTrades(uint256 soulId) external view returns (Trade[] memory) {
        return soulTrades[soulId];
    }
    
    /**
     * @dev Get soul upgrades
     * @param soulId Soul ID
     * @return Array of upgrade IDs
     */
    function getSoulUpgrades(uint256 soulId) external view returns (uint256[] memory) {
        return soulUpgrades[soulId];
    }
    
    /**
     * @dev Add or update an upgrade
     * @param upgradeId Upgrade ID
     * @param name Upgrade name
     * @param description Upgrade description
     * @param cost Upgrade cost
     * @param requirements Level requirements
     */
    function addUpgrade(
        uint256 upgradeId,
        string memory name,
        string memory description,
        uint256 cost,
        uint256[] memory requirements
    ) external onlyOwner {
        upgrades[upgradeId] = Upgrade({
            upgradeId: upgradeId,
            name: name,
            description: description,
            cost: cost,
            isActive: true,
            requirements: requirements
        });
    }
    
    /**
     * @dev Pause contract (emergency only)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Override required functions
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Internal function to remove soul from user's collection
     */
    function _removeFromUserSouls(address user, uint256 soulId) internal {
        uint256[] storage userSoulsArray = userSouls[user];
        for (uint256 i = 0; i < userSoulsArray.length; i++) {
            if (userSoulsArray[i] == soulId) {
                userSoulsArray[i] = userSoulsArray[userSoulsArray.length - 1];
                userSoulsArray.pop();
                break;
            }
        }
    }
} 