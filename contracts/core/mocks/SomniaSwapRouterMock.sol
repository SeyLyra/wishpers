// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SomniaSwapRouterMock
 * @notice Mock router for Somnia Swap DApp - Hackathon Demo Version
 * @dev Simplified implementation for demonstration purposes
 */
contract SomniaSwapRouterMock {
    using SafeERC20 for IERC20;

    address public immutable WSOMM; // Wrapped Somnia token
    
    // Simple 1:1 swap ratio for demo (can be adjusted)
    uint256 public constant DEFAULT_SLIPPAGE = 2; // 2% slippage
    uint256 public constant BASIS_POINTS = 10000;
    
    mapping(address => mapping(address => uint256)) public exchangeRates; // tokenIn => tokenOut => rate (in basis points)
    
    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed to
    );

    constructor(address _wSomm) {
        WSOMM = _wSomm;
    }

    /**
     * @notice Set exchange rate for token pair (for demo)
     * @dev Rate in basis points (10000 = 1:1)
     */
    function setExchangeRate(
        address tokenIn,
        address tokenOut,
        uint256 rate
    ) external {
        exchangeRates[tokenIn][tokenOut] = rate;
        exchangeRates[tokenOut][tokenIn] = BASIS_POINTS * BASIS_POINTS / rate; // Inverse
    }

    /**
     * @notice Swap exact tokens for tokens
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "SomniaSwapRouter: EXPIRED");
        require(path.length >= 2, "SomniaSwapRouter: INVALID_PATH");
        require(to != address(0), "SomniaSwapRouter: INVALID_RECIPIENT");

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        uint256 currentAmount = amountIn;
        
        // Calculate swap amounts through path
        for (uint256 i = 0; i < path.length - 1; i++) {
            address tokenIn = path[i];
            address tokenOut = path[i + 1];
            
            uint256 amountOut = _calculateSwapAmount(tokenIn, tokenOut, currentAmount);
            amounts[i + 1] = amountOut;
            currentAmount = amountOut;
        }

        uint256 finalAmount = amounts[amounts.length - 1];
        require(finalAmount >= amountOutMin, "SomniaSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");

        // Transfer tokens
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(path[path.length - 1]).safeTransfer(to, finalAmount);

        emit SwapExecuted(path[0], path[path.length - 1], amountIn, finalAmount, to);

        return amounts;
    }

    /**
     * @notice Swap tokens for exact tokens
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "SomniaSwapRouter: EXPIRED");
        require(path.length >= 2, "SomniaSwapRouter: INVALID_PATH");

        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        // Calculate required input
        uint256 requiredInput = _calculateRequiredInput(path, amountOut);
        require(requiredInput <= amountInMax, "SomniaSwapRouter: EXCESSIVE_INPUT_AMOUNT");

        amounts[0] = requiredInput;

        // Transfer tokens
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), requiredInput);
        IERC20(path[path.length - 1]).safeTransfer(to, amountOut);

        emit SwapExecuted(path[0], path[path.length - 1], requiredInput, amountOut, to);

        return amounts;
    }

    /**
     * @notice Get amounts out for a swap
     */
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "SomniaSwapRouter: INVALID_PATH");
        
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        
        uint256 currentAmount = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            uint256 amountOut = _calculateSwapAmount(path[i], path[i + 1], currentAmount);
            amounts[i + 1] = amountOut;
            currentAmount = amountOut;
        }
    }

    /**
     * @notice Get amounts in for a swap
     */
    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "SomniaSwapRouter: INVALID_PATH");
        
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        
        uint256 currentAmount = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            uint256 amountIn = _calculateRequiredInputForPair(path[i], path[i - 1], currentAmount);
            amounts[i - 1] = amountIn;
            currentAmount = amountIn;
        }
    }

    /**
     * @notice Calculate swap amount using exchange rate
     */
    function _calculateSwapAmount(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256) {
        uint256 rate = exchangeRates[tokenIn][tokenOut];
        
        if (rate == 0) {
            // Default 1:1 if no rate set
            rate = BASIS_POINTS;
        }
        
        // Apply default slippage
        uint256 amountOut = (amountIn * rate) / BASIS_POINTS;
        uint256 afterSlippage = amountOut * (BASIS_POINTS - DEFAULT_SLIPPAGE) / BASIS_POINTS;
        
        return afterSlippage;
    }

    /**
     * @notice Calculate required input for path
     */
    function _calculateRequiredInput(
        address[] memory path,
        uint256 amountOut
    ) internal view returns (uint256) {
        uint256 currentAmount = amountOut;
        
        for (uint256 i = path.length - 1; i > 0; i--) {
            currentAmount = _calculateRequiredInputForPair(path[i], path[i - 1], currentAmount);
        }
        
        return currentAmount;
    }

    /**
     * @notice Calculate required input for single pair
     */
    function _calculateRequiredInputForPair(
        address tokenOut,
        address tokenIn,
        uint256 amountOut
    ) internal view returns (uint256) {
        uint256 rate = exchangeRates[tokenIn][tokenOut];
        
        if (rate == 0) {
            rate = BASIS_POINTS; // Default 1:1
        }
        
        // Reverse calculation with slippage
        uint256 amountIn = (amountOut * BASIS_POINTS) / rate;
        uint256 withSlippage = amountIn * BASIS_POINTS / (BASIS_POINTS - DEFAULT_SLIPPAGE);
        
        return withSlippage;
    }
}

