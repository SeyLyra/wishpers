// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

/**
 * @title SomniaLendingPoolMock
 * @notice Mock lending pool for Somnia - Hackathon Demo Version
 * @dev Simplified implementation for demonstration purposes
 */
contract SomniaLendingPoolMock {
    using SafeERC20 for IERC20;

    struct ReserveData {
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 liquidityRate; // APY in basis points
        uint256 variableBorrowRate; // APY in basis points
        uint256 stableBorrowRate; // APY in basis points
    }

    mapping(address => ReserveData) public reserves;
    mapping(address => address) public aTokens; // asset => aToken
    mapping(address => bool) public isReserve;
    
    uint256 public constant DEFAULT_LIQUIDITY_RATE = 500; // 5% APY
    uint256 public constant DEFAULT_BORROW_RATE = 800; // 8% APY
    uint256 public constant LTV = 7500; // 75% loan-to-value
    
    event Deposit(address indexed asset, uint256 amount, address indexed onBehalfOf);
    event Withdraw(address indexed asset, uint256 amount, address indexed to);
    event Borrow(address indexed asset, uint256 amount, uint256 interestRateMode, address indexed onBehalfOf);
    event Repay(address indexed asset, uint256 amount, uint256 rateMode, address indexed onBehalfOf);

    /**
     * @notice Register a reserve asset
     */
    function registerReserve(
        address asset,
        address aToken
    ) external {
        require(asset != address(0), "Invalid asset");
        require(aToken != address(0), "Invalid aToken");
        
        isReserve[asset] = true;
        aTokens[asset] = aToken;
        
        reserves[asset] = ReserveData({
            availableLiquidity: 0,
            totalStableDebt: 0,
            totalVariableDebt: 0,
            liquidityRate: DEFAULT_LIQUIDITY_RATE,
            variableBorrowRate: DEFAULT_BORROW_RATE,
            stableBorrowRate: DEFAULT_BORROW_RATE + 200 // Slightly higher
        });
    }

    /**
     * @notice Add initial liquidity (for demo)
     */
    function addLiquidity(address asset, uint256 amount) external {
        require(isReserve[asset], "Not a reserve");
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        reserves[asset].availableLiquidity += amount;
    }

    /**
     * @notice Deposit assets to lending pool
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        require(isReserve[asset], "Not a reserve");
        require(amount > 0, "Invalid amount");
        
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        
        reserves[asset].availableLiquidity += amount;
        
        // Mint aToken to depositor (simplified - would use actual aToken contract)
        // For demo, we just track the deposit
        
        emit Deposit(asset, amount, onBehalfOf);
    }

    /**
     * @notice Withdraw assets from lending pool
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(isReserve[asset], "Not a reserve");
        require(to != address(0), "Invalid recipient");
        
        ReserveData storage reserve = reserves[asset];
        uint256 available = reserve.availableLiquidity;
        
        if (amount == type(uint256).max) {
            amount = available;
        }
        
        require(available >= amount, "Insufficient liquidity");
        
        reserve.availableLiquidity -= amount;
        IERC20(asset).safeTransfer(to, amount);
        
        emit Withdraw(asset, amount, to);
        
        return amount;
    }

    /**
     * @notice Borrow assets from lending pool
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external {
        require(isReserve[asset], "Not a reserve");
        require(amount > 0, "Invalid amount");
        
        ReserveData storage reserve = reserves[asset];
        require(reserve.availableLiquidity >= amount, "Insufficient liquidity");
        
        reserve.availableLiquidity -= amount;
        
        if (interestRateMode == 1) {
            reserve.totalStableDebt += amount;
        } else {
            reserve.totalVariableDebt += amount;
        }
        
        IERC20(asset).safeTransfer(onBehalfOf, amount);
        
        emit Borrow(asset, amount, interestRateMode, onBehalfOf);
    }

    /**
     * @notice Repay borrowed assets
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256) {
        require(isReserve[asset], "Not a reserve");
        
        ReserveData storage reserve = reserves[asset];
        
        if (amount == type(uint256).max) {
            if (rateMode == 1) {
                amount = reserve.totalStableDebt;
            } else {
                amount = reserve.totalVariableDebt;
            }
        }
        
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        
        reserve.availableLiquidity += amount;
        
        if (rateMode == 1) {
            if (reserve.totalStableDebt >= amount) {
                reserve.totalStableDebt -= amount;
            }
        } else {
            if (reserve.totalVariableDebt >= amount) {
                reserve.totalVariableDebt -= amount;
            }
        }
        
        emit Repay(asset, amount, rateMode, onBehalfOf);
        
        return amount;
    }

    /**
     * @notice Get reserve data
     */
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
        )
    {
        ReserveData memory reserve = reserves[asset];
        return (
            reserve.availableLiquidity,
            reserve.totalStableDebt,
            reserve.totalVariableDebt,
            reserve.liquidityRate,
            reserve.variableBorrowRate,
            reserve.stableBorrowRate
        );
    }

    /**
     * @notice Set interest rates (for demo customization)
     */
    function setRates(
        address asset,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 stableBorrowRate
    ) external {
        require(isReserve[asset], "Not a reserve");
        ReserveData storage reserve = reserves[asset];
        reserve.liquidityRate = liquidityRate;
        reserve.variableBorrowRate = variableBorrowRate;
        reserve.stableBorrowRate = stableBorrowRate;
    }
}

