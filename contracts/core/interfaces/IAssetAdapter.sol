// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAssetAdapter
 * @notice Interface for DeFi protocol adapters (Uniswap, Aave, Sushiswap, etc.)
 */
interface IAssetAdapter {
    /**
     * @notice Swap tokens
     * @param tokenIn Token to swap from
     * @param tokenOut Token to swap to
     * @param amountIn Amount of tokenIn
     * @param minAmountOut Minimum amount of tokenOut expected
     * @return amountOut Actual amount of tokenOut received
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);

    /**
     * @notice Get value of amount in base token
     * @param token Token address
     * @param amount Amount of token
     * @return value Value in base token
     */
    function getValueInBaseToken(address token, uint256 amount) 
        external 
        view 
        returns (uint256 value);

    /**
     * @notice Get quote for swap
     * @param tokenIn Token to swap from
     * @param tokenOut Token to swap to
     * @param amountIn Amount of tokenIn
     * @return amountOut Expected amount of tokenOut
     */
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    /**
     * @notice Get adapter name
     */
    function adapterName() external pure returns (string memory);

    /**
     * @notice Check if adapter supports token pair
     */
    function supportsPair(address tokenIn, address tokenOut) 
        external 
        view 
        returns (bool);
}

