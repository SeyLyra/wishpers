// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockLendingPool
 * @notice Minimal lending pool mock for Somnia testnet integration.
 *         Provides reserve data and basic deposit/withdraw accounting without real interest.
 */
contract MockLendingPool {
    struct ReserveData {
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 liquidityRate;      // in ray, mocked as 0
        uint256 variableBorrowRate; // in ray, mocked as 0
        uint256 stableBorrowRate;   // in ray, mocked as 0
        uint256 averageStableBorrowRate;
    }

    // asset => reserve data
    mapping(address => ReserveData) public reserves;
    // user => asset => balance (for bookkeeping)
    mapping(address => mapping(address => uint256)) public balances;

    event ReserveConfigured(address indexed asset, uint256 initialLiquidity);
    event Deposit(address indexed asset, address indexed user, uint256 amount);
    event Withdraw(address indexed asset, address indexed user, uint256 amount);

    function configureReserve(address asset, uint256 initialLiquidity) external {
        reserves[asset].availableLiquidity = initialLiquidity;
        emit ReserveConfigured(asset, initialLiquidity);
    }

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate
        )
    {
        ReserveData memory r = reserves[asset];
        return (
            r.availableLiquidity,
            r.totalStableDebt,
            r.totalVariableDebt,
            r.liquidityRate,
            r.variableBorrowRate,
            r.stableBorrowRate,
            r.averageStableBorrowRate
        );
    }

    // Simplified deposit: pulls tokens from msg.sender and increases liquidity and user balance
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 /*referralCode*/ ) external {
        require(amount > 0, "amount=0");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        reserves[asset].availableLiquidity += amount;
        balances[onBehalfOf][asset] += amount;
        emit Deposit(asset, onBehalfOf, amount);
    }

    // Simplified withdraw: decreases liquidity and transfers to user
    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        require(amount > 0, "amount=0");
        uint256 bal = balances[msg.sender][asset];
        require(bal >= amount, "insufficient user balance");
        balances[msg.sender][asset] = bal - amount;

        uint256 liq = reserves[asset].availableLiquidity;
        require(liq >= amount, "insufficient liquidity");
        reserves[asset].availableLiquidity = liq - amount;
        IERC20(asset).transfer(to, amount);
        emit Withdraw(asset, msg.sender, amount);
        return amount;
    }
}