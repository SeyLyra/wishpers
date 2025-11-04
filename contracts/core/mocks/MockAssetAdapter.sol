// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IAssetAdapter.sol";

/**
 * @title MockAssetAdapter
 * @notice Minimal adapter for testing on Somnia testnet. Provides 1:1 pricing
 *         to the base token and a simple quote. Swap is intentionally disabled.
 */
contract MockAssetAdapter is IAssetAdapter {
    address public immutable baseToken;

    constructor(address _baseToken) {
        require(_baseToken != address(0), "Invalid base token");
        baseToken = _baseToken;
    }

    /**
     * @notice Swap is not supported in the mock adapter
     */
    function swap(
        address /* tokenIn */, 
        address /* tokenOut */, 
        uint256 amountIn, 
        uint256 /* minAmountOut */
    ) external pure returns (uint256 amountOut) {
        // For demo purposes, do not move funds; return 1:1 and rely on Vault accounting
        // If swap functionality is needed, use SomniaSwapAdapter with a real router
        revert("MockAdapter: swap unsupported");
    }

    /**
     * @notice 1:1 value in base token for demo purposes
     */
    function getValueInBaseToken(address /* token */, uint256 amount)
        external
        pure
        returns (uint256 value)
    {
        return amount;
    }

    /**
     * @notice 1:1 quote for demo purposes
     */
    function getQuote(
        address /* tokenIn */, 
        address /* tokenOut */, 
        uint256 amountIn
    ) external pure returns (uint256 amountOut) {
        return amountIn;
    }

    function adapterName() external pure returns (string memory) {
        return "Mock Adapter";
    }

    function supportsPair(address tokenIn, address tokenOut)
        external
        pure
        returns (bool)
    {
        return tokenIn != tokenOut;
    }
}