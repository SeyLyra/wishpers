// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IAssetAdapter.sol";

/**
 * @title SomniaSwapAdapter
 * @notice Adapter for Somnia Swap DApp - Somnia's native DEX protocol
 */
interface ISomniaSwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function WSOMM() external pure returns (address); // Wrapped Somnia token
}

/**
 * @title SomniaSwapAdapter
 * @notice Adapter for Somnia Swap DApp and local liquidity pools
 */
contract SomniaSwapAdapter is IAssetAdapter {
    using SafeERC20 for IERC20;

    ISomniaSwapRouter public router;
    address public baseToken; // Native token (e.g., SOMM or USDC on Somnia)
    address public wSomm; // Wrapped Somnia token

    mapping(address => bool) public supportedTokens;
    mapping(address => mapping(address => address)) public liquidityPools; // tokenA => tokenB => poolAddress

    event PoolRegistered(address indexed tokenA, address indexed tokenB, address indexed pool);
    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _router, address _baseToken) {
        router = ISomniaSwapRouter(_router);
        baseToken = _baseToken;
        wSomm = router.WSOMM();
        
        supportedTokens[_baseToken] = true;
        supportedTokens[wSomm] = true;
    }

    /**
     * @notice Register a local liquidity pool
     */
    function registerPool(
        address tokenA,
        address tokenB,
        address poolAddress
    ) external {
        require(tokenA != tokenB, "Same token");
        require(poolAddress != address(0), "Invalid pool");
        require(tokenA < tokenB, "Invalid order"); // Ensure consistent ordering
        
        liquidityPools[tokenA][tokenB] = poolAddress;
        liquidityPools[tokenB][tokenA] = poolAddress;
        
        supportedTokens[tokenA] = true;
        supportedTokens[tokenB] = true;
        
        emit PoolRegistered(tokenA, tokenB, poolAddress);
    }

    /**
     * @notice Execute swap through Somnia Swap
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external override returns (uint256) {
        require(amountIn > 0, "Invalid amount");
        require(tokenIn != tokenOut, "Same token");
        require(supportedTokens[tokenIn], "TokenIn not supported");
        require(supportedTokens[tokenOut], "TokenOut not supported");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(address(router), amountIn);

        // Build swap path
        address[] memory path = _buildPath(tokenIn, tokenOut);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            path,
            msg.sender,
            block.timestamp + 300 // 5 minute deadline
        );

        uint256 amountOut = amounts[amounts.length - 1];
        
        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
        
        return amountOut;
    }

    /**
     * @notice Get value in base token
     */
    function getValueInBaseToken(address token, uint256 amount) 
        external 
        view 
        override 
        returns (uint256) 
    {
        if (token == baseToken) {
            return amount;
        }

        address[] memory path = _buildPath(token, baseToken);
        uint256[] memory amounts = router.getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }

    /**
     * @notice Get swap quote
     */
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view override returns (uint256) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        address[] memory path = _buildPath(tokenIn, tokenOut);
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        return amounts[amounts.length - 1];
    }

    /**
     * @notice Build optimal swap path
     */
    function _buildPath(address tokenIn, address tokenOut) 
        internal 
        view 
        returns (address[] memory path) 
    {
        // Check if direct pool exists
        address pool = liquidityPools[tokenIn][tokenOut];
        if (pool != address(0)) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            return path;
        }

        // Route through WSOMM if needed
        bool needsWrapping = (tokenIn != wSomm && tokenOut != wSomm);
        
        if (needsWrapping) {
            // Check if paths through WSOMM exist
            address pool1 = liquidityPools[tokenIn][wSomm];
            address pool2 = liquidityPools[wSomm][tokenOut];
            
            if (pool1 != address(0) && pool2 != address(0)) {
                path = new address[](3);
                path[0] = tokenIn;
                path[1] = wSomm;
                path[2] = tokenOut;
                return path;
            }
        }

        // Fallback: route through base token
        path = new address[](3);
        path[0] = tokenIn;
        path[1] = baseToken;
        path[2] = tokenOut;
    }

    function adapterName() external pure override returns (string memory) {
        return "Somnia Swap";
    }

    function supportsPair(address tokenIn, address tokenOut) 
        external 
        view 
        override 
        returns (bool) 
    {
        if (tokenIn == tokenOut) return false;
        if (!supportedTokens[tokenIn] || !supportedTokens[tokenOut]) return false;
        
        // Check if direct pool exists or can route through WSOMM/base
        return liquidityPools[tokenIn][tokenOut] != address(0) ||
               (liquidityPools[tokenIn][wSomm] != address(0) && 
                liquidityPools[wSomm][tokenOut] != address(0)) ||
               (liquidityPools[tokenIn][baseToken] != address(0) && 
                liquidityPools[baseToken][tokenOut] != address(0));
    }

    /**
     * @notice Add supported token
     */
    function addSupportedToken(address token) external {
        supportedTokens[token] = true;
    }
}

