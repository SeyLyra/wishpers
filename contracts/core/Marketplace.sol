// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Marketplace
 * @notice Marketplace for buying/selling agent strategies, upgrades, and insights
 */
contract Marketplace is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant LISTER_ROLE = keccak256("LISTER_ROLE");

    enum ItemType {
        Strategy,
        Upgrade,
        Insight,
        ModelWeights,
        Soul  // Added Soul type for selling AI agents
    }

    struct MarketplaceItem {
        uint256 itemId;
        address seller;
        ItemType itemType;
        string name;
        string description;
        string metadataURI; // IPFS or other URI
        address paymentToken;
        uint256 price;
        bool active;
        uint256 createdAt;
        uint256 salesCount;
        uint256 totalRevenue;
        address soulAddress; // Agent contract address (for Soul type items)
    }

    struct Rating {
        address rater;
        uint256 rating; // 1-5 stars
        string comment;
        uint256 timestamp;
    }

    mapping(uint256 => MarketplaceItem) public items;
    mapping(uint256 => Rating[]) public itemRatings;
    mapping(uint256 => mapping(address => bool)) public hasPurchased;
    mapping(address => uint256[]) public sellerItems;
    
    uint256 public itemCounter;
    address public treasury; // Revenue share address
    uint256 public platformFee; // Basis points (10000 = 100%)
    uint256 public constant MAX_FEE = 1000; // 10% max

    IERC20 public paymentToken;

    event ItemListed(
        uint256 indexed itemId,
        address indexed seller,
        ItemType itemType,
        string name,
        uint256 price
    );
    event ItemPurchased(
        uint256 indexed itemId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );
    event ItemRated(
        uint256 indexed itemId,
        address indexed rater,
        uint256 rating,
        string comment
    );
    event ItemDeactivated(uint256 indexed itemId);
    event PlatformFeeUpdated(uint256 newFee);
    event TreasuryUpdated(address newTreasury);

    constructor(address _paymentToken, address _treasury) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LISTER_ROLE, msg.sender);
        
        paymentToken = IERC20(_paymentToken);
        treasury = _treasury;
        platformFee = 250; // 2.5% default
    }

    /**
     * @notice List a new item for sale
     */
    function listItem(
        ItemType itemType,
        string memory name,
        string memory description,
        string memory metadataURI,
        address _paymentToken,
        uint256 price
    ) external onlyRole(LISTER_ROLE) returns (uint256) {
        require(price > 0, "Price must be > 0");
        require(bytes(name).length > 0, "Name required");

        itemCounter++;

        items[itemCounter] = MarketplaceItem({
            itemId: itemCounter,
            seller: msg.sender,
            itemType: itemType,
            name: name,
            description: description,
            metadataURI: metadataURI,
            paymentToken: _paymentToken,
            price: price,
            active: true,
            createdAt: block.timestamp,
            salesCount: 0,
            totalRevenue: 0,
            soulAddress: address(0)
        });

        sellerItems[msg.sender].push(itemCounter);

        emit ItemListed(itemCounter, msg.sender, itemType, name, price);

        return itemCounter;
    }

    /**
     * @notice List a soul (AI agent) for sale
     * @param soulAddress The agent contract address
     * @param name Soul name
     * @param description Soul description
     * @param metadataURI IPFS URI with soul details
     * @param price Sale price in payment token
     */
    function listSoul(
        address soulAddress,
        string memory name,
        string memory description,
        string memory metadataURI,
        uint256 price
    ) external returns (uint256) {
        require(price > 0, "Price must be > 0");
        require(bytes(name).length > 0, "Name required");
        require(soulAddress != address(0), "Invalid soul address");

        itemCounter++;

        items[itemCounter] = MarketplaceItem({
            itemId: itemCounter,
            seller: msg.sender,
            itemType: ItemType.Soul,
            name: name,
            description: description,
            metadataURI: metadataURI,
            paymentToken: address(0), // Use native STT for soul sales
            price: price,
            active: true,
            createdAt: block.timestamp,
            salesCount: 0,
            totalRevenue: 0,
            soulAddress: soulAddress
        });

        sellerItems[msg.sender].push(itemCounter);

        emit ItemListed(itemCounter, msg.sender, ItemType.Soul, name, price);

        return itemCounter;
    }

    /**
     * @notice Purchase an item
     */
    function purchaseItem(uint256 itemId) external payable nonReentrant {
        MarketplaceItem storage item = items[itemId];
        
        require(item.active, "Item not active");
        require(item.seller != msg.sender, "Cannot buy own item");
        require(!hasPurchased[itemId][msg.sender], "Already purchased");
        
        uint256 amountToPay = item.price;
        uint256 feeAmount = (amountToPay * platformFee) / 10000;
        uint256 sellerAmount = amountToPay - feeAmount;

        if (item.paymentToken == address(0)) {
            // Native STT payment (no ERC20 address)
            require(msg.value == amountToPay, "Incorrect native payment amount");

            // Distribute native funds
            if (feeAmount > 0) {
                (bool feeSent, ) = payable(treasury).call{value: feeAmount}("");
                require(feeSent, "Treasury payment failed");
            }
            (bool sellerSent, ) = payable(item.seller).call{value: sellerAmount}("");
            require(sellerSent, "Seller payment failed");
        } else {
            // ERC20 payment
            IERC20 itemPaymentToken = IERC20(item.paymentToken);

            // Transfer payment
            itemPaymentToken.safeTransferFrom(msg.sender, address(this), amountToPay);
            
            // Distribute funds
            if (feeAmount > 0) {
                itemPaymentToken.safeTransfer(treasury, feeAmount);
            }
            itemPaymentToken.safeTransfer(item.seller, sellerAmount);
        }
        
        // Update item stats
        item.salesCount++;
        item.totalRevenue += sellerAmount;
        hasPurchased[itemId][msg.sender] = true;
        
        emit ItemPurchased(itemId, msg.sender, item.seller, item.price);
    }

    /**
     * @notice Rate an item
     */
    function rateItem(
        uint256 itemId,
        uint256 rating,
        string memory comment
    ) external {
        require(rating >= 1 && rating <= 5, "Rating must be 1-5");
        require(hasPurchased[itemId][msg.sender], "Must purchase to rate");
        
        // Check if already rated
        bool alreadyRated = false;
        for (uint256 i = 0; i < itemRatings[itemId].length; i++) {
            if (itemRatings[itemId][i].rater == msg.sender) {
                alreadyRated = true;
                itemRatings[itemId][i].rating = rating;
                itemRatings[itemId][i].comment = comment;
                itemRatings[itemId][i].timestamp = block.timestamp;
                break;
            }
        }
        
        if (!alreadyRated) {
            itemRatings[itemId].push(Rating({
                rater: msg.sender,
                rating: rating,
                comment: comment,
                timestamp: block.timestamp
            }));
        }
        
        emit ItemRated(itemId, msg.sender, rating, comment);
    }

    /**
     * @notice Get average rating for an item
     */
    function getAverageRating(uint256 itemId) external view returns (uint256) {
        Rating[] memory ratings = itemRatings[itemId];
        if (ratings.length == 0) return 0;
        
        uint256 total = 0;
        for (uint256 i = 0; i < ratings.length; i++) {
            total += ratings[i].rating;
        }
        
        return total / ratings.length;
    }

    /**
     * @notice Deactivate an item
     */
    function deactivateItem(uint256 itemId) external {
        MarketplaceItem storage item = items[itemId];
        require(item.seller == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        item.active = false;
        emit ItemDeactivated(itemId);
    }

    /**
     * @notice Update platform fee
     */
    function setPlatformFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_fee <= MAX_FEE, "Fee too high");
        platformFee = _fee;
        emit PlatformFeeUpdated(_fee);
    }

    /**
     * @notice Update treasury address
     */
    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_treasury != address(0), "Invalid treasury");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /**
     * @notice Get item details
     */
    function getItem(uint256 itemId) external view returns (MarketplaceItem memory) {
        return items[itemId];
    }

    /**
     * @notice Get seller's items
     */
    function getSellerItems(address seller) external view returns (uint256[] memory) {
        return sellerItems[seller];
    }

    /**
     * @notice Get item ratings
     */
    function getItemRatings(uint256 itemId) external view returns (Rating[] memory) {
        return itemRatings[itemId];
    }

    /**
     * @notice Check if user has purchased
     */
    function hasUserPurchased(uint256 itemId, address user) external view returns (bool) {
        return hasPurchased[itemId][user];
    }

    /**
     * @notice Get all active soul listings
     */
    function getActiveSoulListings() external view returns (MarketplaceItem[] memory) {
        // Count active soul listings
        uint256 count = 0;
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].active && items[i].itemType == ItemType.Soul) {
                count++;
            }
        }

        // Build array of active souls
        MarketplaceItem[] memory soulListings = new MarketplaceItem[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].active && items[i].itemType == ItemType.Soul) {
                soulListings[index] = items[i];
                index++;
            }
        }

        return soulListings;
    }

    /**
     * @notice Get all items of a specific type
     */
    function getItemsByType(ItemType itemType) external view returns (MarketplaceItem[] memory) {
        // Count items of type
        uint256 count = 0;
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].active && items[i].itemType == itemType) {
                count++;
            }
        }

        // Build array
        MarketplaceItem[] memory typeItems = new MarketplaceItem[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCounter; i++) {
            if (items[i].active && items[i].itemType == itemType) {
                typeItems[index] = items[i];
                index++;
            }
        }

        return typeItems;
    }
}

