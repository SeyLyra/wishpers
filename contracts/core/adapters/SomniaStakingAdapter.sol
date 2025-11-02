// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IAssetAdapter.sol";

/**
 * @title SomniaStakingAdapter
 * @notice Adapter for Somnia staking protocols (liquid staking, yield farming, etc.)
 */

interface ISomniaStakingPool {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function claimRewards() external;
    function getStakedBalance(address account) external view returns (uint256);
    function getRewardRate() external view returns (uint256); // APY or reward rate
    function getTotalStaked() external view returns (uint256);
}

interface ISomniaLiquidStaking {
    function stake(uint256 amount) external returns (uint256); // Returns staked token amount
    function unstake(uint256 amount) external returns (uint256); // Returns original token amount
    function getStakedToken() external view returns (address); // Returns liquid staking token address
    function getExchangeRate() external view returns (uint256); // Staking token to original token rate
}

interface ISomniaYieldFarm {
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function harvest(uint256 pid) external;
    function pendingRewards(uint256 pid, address user) external view returns (uint256);
}

/**
 * @title SomniaStakingAdapter
 * @notice Adapter for Somnia staking and yield farming protocols
 */
contract SomniaStakingAdapter is IAssetAdapter {
    using SafeERC20 for IERC20;

    address public baseToken;
    
    mapping(address => ISomniaStakingPool) public stakingPools;
    mapping(address => ISomniaLiquidStaking) public liquidStaking;
    mapping(address => ISomniaYieldFarm) public yieldFarms;
    mapping(address => uint256) public poolIds; // For yield farms
    
    mapping(address => bool) public supportedTokens;

    enum StakingType {
        Standard,
        Liquid,
        YieldFarm
    }
    
    mapping(address => StakingType) public tokenStakingType;

    event PoolRegistered(address indexed token, StakingType stakingType);
    event Staked(address indexed token, uint256 amount);
    event Unstaked(address indexed token, uint256 amount);
    event RewardsClaimed(address indexed token, uint256 amount);

    constructor(address _baseToken) {
        baseToken = _baseToken;
        supportedTokens[_baseToken] = true;
    }

    /**
     * @notice Register standard staking pool
     */
    function registerStakingPool(
        address token,
        ISomniaStakingPool pool
    ) external {
        require(address(pool) != address(0), "Invalid pool");
        stakingPools[token] = pool;
        supportedTokens[token] = true;
        tokenStakingType[token] = StakingType.Standard;
        
        emit PoolRegistered(token, StakingType.Standard);
    }

    /**
     * @notice Register liquid staking
     */
    function registerLiquidStaking(
        address token,
        ISomniaLiquidStaking staking
    ) external {
        require(address(staking) != address(0), "Invalid staking");
        liquidStaking[token] = staking;
        supportedTokens[token] = true;
        tokenStakingType[token] = StakingType.Liquid;
        
        emit PoolRegistered(token, StakingType.Liquid);
    }

    /**
     * @notice Register yield farm
     */
    function registerYieldFarm(
        address token,
        ISomniaYieldFarm farm,
        uint256 poolId
    ) external {
        require(address(farm) != address(0), "Invalid farm");
        yieldFarms[token] = farm;
        poolIds[token] = poolId;
        supportedTokens[token] = true;
        tokenStakingType[token] = StakingType.YieldFarm;
        
        emit PoolRegistered(token, StakingType.YieldFarm);
    }

    /**
     * @notice Stake tokens (swap equivalent - stake one token, get staking rewards)
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external override returns (uint256) {
        require(amountIn > 0, "Invalid amount");
        
        // For staking, we stake tokenIn and might receive stakedTokenOut or rewards
        // This is simplified - in practice, staking doesn't directly swap tokens
        // but we can treat staking as a "swap" that yields staked tokens or rewards
        
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        
        StakingType stakingType = tokenStakingType[tokenIn];
        
        if (stakingType == StakingType.Liquid) {
            IERC20(tokenIn).safeIncreaseAllowance(address(liquidStaking[tokenIn]), amountIn);
            uint256 stakedAmount = liquidStaking[tokenIn].stake(amountIn);
            
            address stakedToken = liquidStaking[tokenIn].getStakedToken();
            uint256 balance = IERC20(stakedToken).balanceOf(address(this));
            
            require(balance >= minAmountOut, "Slippage too high");
            IERC20(stakedToken).safeTransfer(msg.sender, balance);
            
            emit Staked(tokenIn, amountIn);
            return balance;
            
        } else if (stakingType == StakingType.YieldFarm) {
            IERC20(tokenIn).safeIncreaseAllowance(address(yieldFarms[tokenIn]), amountIn);
            yieldFarms[tokenIn].deposit(poolIds[tokenIn], amountIn);
            
            emit Staked(tokenIn, amountIn);
            return amountIn; // User gets LP token or staking receipt
            
        } else {
            // Standard staking
            IERC20(tokenIn).safeIncreaseAllowance(address(stakingPools[tokenIn]), amountIn);
            stakingPools[tokenIn].stake(amountIn);
            
            emit Staked(tokenIn, amountIn);
            return amountIn;
        }
    }

    /**
     * @notice Unstake tokens
     */
    function unstake(address token, uint256 amount) external returns (uint256) {
        StakingType stakingType = tokenStakingType[token];
        
        if (stakingType == StakingType.Liquid) {
            uint256 unstaked = liquidStaking[token].unstake(amount);
            IERC20(token).safeTransfer(msg.sender, unstaked);
            emit Unstaked(token, unstaked);
            return unstaked;
            
        } else if (stakingType == StakingType.YieldFarm) {
            yieldFarms[token].withdraw(poolIds[token], amount);
            IERC20(token).safeTransfer(msg.sender, amount);
            emit Unstaked(token, amount);
            return amount;
            
        } else {
            stakingPools[token].unstake(amount);
            IERC20(token).safeTransfer(msg.sender, amount);
            emit Unstaked(token, amount);
            return amount;
        }
    }

    /**
     * @notice Claim staking rewards
     */
    function claimRewards(address token) external returns (uint256) {
        StakingType stakingType = tokenStakingType[token];
        uint256 rewards = 0;
        
        if (stakingType == StakingType.YieldFarm) {
            yieldFarms[token].harvest(poolIds[token]);
            // Rewards are typically sent to the caller
        } else if (stakingType == StakingType.Standard) {
            stakingPools[token].claimRewards();
        }
        
        emit RewardsClaimed(token, rewards);
        return rewards;
    }

    /**
     * @notice Get value in base token (includes accrued rewards)
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

        StakingType stakingType = tokenStakingType[token];
        
        if (stakingType == StakingType.Liquid) {
            // Get exchange rate for liquid staking token
            uint256 exchangeRate = liquidStaking[token].getExchangeRate();
            address originalToken = token;
            // Simplified: convert via exchange rate
            return amount; // Would need more complex calculation
        }
        
        // For standard staking and yield farms, return 1:1 for now
        // In production, would query actual value including rewards
        return amount;
    }

    /**
     * @notice Get quote (estimated staked amount or rewards)
     */
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view override returns (uint256) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        StakingType stakingType = tokenStakingType[tokenIn];
        
        if (stakingType == StakingType.Liquid) {
            uint256 exchangeRate = liquidStaking[tokenIn].getExchangeRate();
            return (amountIn * exchangeRate) / 1e18; // Assuming 18 decimals
        }
        
        // For other types, estimate based on current staking rates
        return amountIn;
    }

    function adapterName() external pure override returns (string memory) {
        return "Somnia Staking";
    }

    function supportsPair(address tokenIn, address tokenOut) 
        external 
        view 
        override 
        returns (bool) 
    {
        if (tokenIn == tokenOut) return false;
        return supportedTokens[tokenIn] && tokenStakingType[tokenIn] != StakingType.Standard;
    }

    /**
     * @notice Get staking information
     */
    function getStakingInfo(address token) 
        external 
        view 
        returns (
            StakingType stakingType,
            uint256 stakedBalance,
            uint256 rewardRate,
            uint256 totalStaked
        ) 
    {
        stakingType = tokenStakingType[token];
        
        if (stakingType == StakingType.Standard) {
            stakedBalance = stakingPools[token].getStakedBalance(address(this));
            rewardRate = stakingPools[token].getRewardRate();
            totalStaked = stakingPools[token].getTotalStaked();
        } else if (stakingType == StakingType.Liquid) {
            stakedBalance = IERC20(liquidStaking[token].getStakedToken()).balanceOf(address(this));
            rewardRate = liquidStaking[token].getExchangeRate();
            totalStaked = 0; // Would need to query from liquid staking contract
        } else if (stakingType == StakingType.YieldFarm) {
            stakedBalance = 0; // Would need to query from yield farm
            rewardRate = yieldFarms[token].pendingRewards(poolIds[token], address(this));
            totalStaked = 0; // Would need to query from yield farm
        }
    }
}

