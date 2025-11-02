// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IAssetAdapter.sol";

/**
 * @title SomniaLendingAdapter
 * @notice Adapter for Somnia native lending platforms
 */

// Simplified Somnia Lending Pool interface
interface ISomniaLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate
        );
}

interface ISomniaPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

/**
 * @title SomniaLendingAdapter
 * @notice Adapter for Somnia lending platforms (deposit, borrow, lending swaps)
 */
contract SomniaLendingAdapter is IAssetAdapter {
    using SafeERC20 for IERC20;

    ISomniaLendingPool public lendingPool;
    ISomniaPriceOracle public priceOracle;
    address public baseToken;

    mapping(address => bool) public supportedAssets;
    mapping(address => address) public aTokens; // asset => aToken mapping

    event AssetSupported(address indexed asset, address indexed aToken);
    event DepositMade(address indexed asset, uint256 amount);
    event WithdrawalMade(address indexed asset, uint256 amount);

    constructor(
        address _lendingPool,
        address _priceOracle,
        address _baseToken
    ) {
        lendingPool = ISomniaLendingPool(_lendingPool);
        priceOracle = ISomniaPriceOracle(_priceOracle);
        baseToken = _baseToken;
    }

    /**
     * @notice Register supported asset and its aToken
     */
    function registerAsset(address asset, address aToken) external {
        require(asset != address(0), "Invalid asset");
        require(aToken != address(0), "Invalid aToken");
        
        supportedAssets[asset] = true;
        aTokens[asset] = aToken;
        
        emit AssetSupported(asset, aToken);
    }

    /**
     * @notice Swap via lending (deposit one asset, borrow another)
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external override returns (uint256) {
        require(amountIn > 0, "Invalid amount");
        require(supportedAssets[tokenIn], "TokenIn not supported");
        require(supportedAssets[tokenOut], "TokenOut not supported");

        // Transfer tokens
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeIncreaseAllowance(address(lendingPool), amountIn);

        // Deposit tokenIn to earn interest
        lendingPool.deposit(tokenIn, amountIn, address(this), 0);
        
        // Calculate borrowable amount (simplified - would use LTV ratio in production)
        uint256 borrowAmount = amountIn; // Simplified
        
        // Borrow tokenOut
        lendingPool.borrow(
            tokenOut,
            borrowAmount,
            2, // Variable interest rate mode
            0,
            address(this)
        );

        // Transfer to user
        uint256 amountOut = IERC20(tokenOut).balanceOf(address(this));
        require(amountOut >= minAmountOut, "Slippage too high");
        
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        return amountOut;
    }

    /**
     * @notice Deposit to lending pool
     */
    function deposit(address asset, uint256 amount, address onBehalfOf) external {
        require(supportedAssets[asset], "Asset not supported");
        require(amount > 0, "Invalid amount");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeIncreaseAllowance(address(lendingPool), amount);

        lendingPool.deposit(asset, amount, onBehalfOf, 0);
        
        emit DepositMade(asset, amount);
    }

    /**
     * @notice Withdraw from lending pool
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        require(supportedAssets[asset], "Asset not supported");
        
        uint256 withdrawn = lendingPool.withdraw(asset, amount, to);
        
        emit WithdrawalMade(asset, withdrawn);
        
        return withdrawn;
    }

    /**
     * @notice Get value in base token using price oracle
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

        uint256 tokenPrice = priceOracle.getAssetPrice(token);
        uint256 basePrice = priceOracle.getAssetPrice(baseToken);
        
        // Prices typically returned with 8 decimals
        // Adjust based on actual token decimals
        return (amount * tokenPrice) / basePrice;
    }

    /**
     * @notice Get quote for swap
     */
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view override returns (uint256) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        uint256 priceIn = priceOracle.getAssetPrice(tokenIn);
        uint256 priceOut = priceOracle.getAssetPrice(tokenOut);
        
        // Account for interest rates and LTV
        // Simplified: direct price conversion
        return (amountIn * priceIn) / priceOut;
    }

    function adapterName() external pure override returns (string memory) {
        return "Somnia Lending";
    }

    function supportsPair(address tokenIn, address tokenOut) 
        external 
        view 
        override 
        returns (bool) 
    {
        if (tokenIn == tokenOut) return false;
        
        // Check if both assets are supported
        if (!supportedAssets[tokenIn] || !supportedAssets[tokenOut]) {
            return false;
        }

        // Check if lending pool has liquidity
        try lendingPool.getReserveData(tokenOut) returns (
            uint256 availableLiquidity,
            uint256 _totalStableDebt,
            uint256 _totalVariableDebt,
            uint256 _liquidityRate,
            uint256 _variableBorrowRate,
            uint256 _stableBorrowRate
        ) {
            // Silence unused variable warnings
            (_totalStableDebt);
            (_totalVariableDebt);
            (_liquidityRate);
            (_variableBorrowRate);
            (_stableBorrowRate);
            return availableLiquidity > 0;
        } catch {
            return false;
        }
    }

    /**
     * @notice Get lending pool data for an asset
     */
    function getLendingData(address asset) 
        external 
        view 
        returns (
            uint256 availableLiquidity,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate
        ) 
    {
        (
            availableLiquidity,
            ,
            ,
            liquidityRate,
            variableBorrowRate,
            stableBorrowRate
        ) = lendingPool.getReserveData(asset);
    }
}

