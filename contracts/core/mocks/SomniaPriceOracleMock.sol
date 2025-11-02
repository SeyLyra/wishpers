// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SomniaPriceOracleMock
 * @notice Mock price oracle for Somnia - Hackathon Demo Version
 * @dev Simplified implementation for demonstration purposes
 */
contract SomniaPriceOracleMock {
    // Prices stored with 8 decimals (standard oracle format)
    uint256 public constant PRICE_DECIMALS = 8;
    
    mapping(address => uint256) public prices; // Token => price (8 decimals)
    
    event PriceUpdated(address indexed asset, uint256 oldPrice, uint256 newPrice);

    /**
     * @notice Set price for an asset
     * @param asset Token address
     * @param price Price with 8 decimals (e.g., 1e8 = $1.00)
     */
    function setAssetPrice(address asset, uint256 price) external {
        uint256 oldPrice = prices[asset];
        prices[asset] = price;
        emit PriceUpdated(asset, oldPrice, price);
    }

    /**
     * @notice Get price for an asset
     */
    function getAssetPrice(address asset) external view returns (uint256) {
        uint256 price = prices[asset];
        require(price > 0, "Price not set");
        return price;
    }

    /**
     * @notice Get prices for multiple assets
     */
    function getAssetsPrices(address[] calldata assets) 
        external 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory result = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            result[i] = prices[assets[i]];
        }
        return result;
    }

    /**
     * @notice Batch set prices
     */
    function setAssetPrices(
        address[] calldata assets,
        uint256[] calldata _prices
    ) external {
        require(assets.length == _prices.length, "Length mismatch");
        
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 oldPrice = prices[assets[i]];
            prices[assets[i]] = _prices[i];
            emit PriceUpdated(assets[i], oldPrice, _prices[i]);
        }
    }
}

