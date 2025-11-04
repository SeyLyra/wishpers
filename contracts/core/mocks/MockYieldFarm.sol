// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockYieldFarm
 * @notice Simple staking/yield farm mock with linear reward accrual per pool.
 */
contract MockYieldFarm {
    struct PoolInfo {
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 rewardRatePerSecond; // rewards per second (in rewardToken units)
        bool exists;
    }

    // pid => pool
    mapping(uint256 => PoolInfo) public pools;
    // user => pid => staked amount
    mapping(address => mapping(uint256 => uint256)) public userStake;
    // user => pid => last reward checkpoint
    mapping(address => mapping(uint256 => uint256)) public lastUpdate;

    event PoolCreated(uint256 indexed pid, address stakingToken, address rewardToken, uint256 rate);
    event Deposit(uint256 indexed pid, address indexed user, uint256 amount);
    event Withdraw(uint256 indexed pid, address indexed user, uint256 amount);
    event Harvest(uint256 indexed pid, address indexed user, uint256 amount);

    function createPool(
        uint256 pid,
        IERC20 stakingToken,
        IERC20 rewardToken,
        uint256 rewardRatePerSecond
    ) external {
        require(!pools[pid].exists, "pool exists");
        pools[pid] = PoolInfo({
            stakingToken: stakingToken,
            rewardToken: rewardToken,
            rewardRatePerSecond: rewardRatePerSecond,
            exists: true
        });
        emit PoolCreated(pid, address(stakingToken), address(rewardToken), rewardRatePerSecond);
    }

    function pendingRewards(uint256 pid, address user) public view returns (uint256) {
        PoolInfo memory p = pools[pid];
        require(p.exists, "pool !exists");
        uint256 staked = userStake[user][pid];
        if (staked == 0) return 0;
        uint256 last = lastUpdate[user][pid];
        if (last == 0) return 0;
        uint256 dt = block.timestamp - last;
        return dt * p.rewardRatePerSecond * staked / 1e18; // stake scaled to 1e18
    }

    function deposit(uint256 pid, uint256 amount) external {
        PoolInfo memory p = pools[pid];
        require(p.exists, "pool !exists");
        require(amount > 0, "amount=0");
        p.stakingToken.transferFrom(msg.sender, address(this), amount);
        // scale stake by 1e18 for reward math simplicity
        userStake[msg.sender][pid] += amount;
        lastUpdate[msg.sender][pid] = block.timestamp;
        emit Deposit(pid, msg.sender, amount);
    }

    function withdraw(uint256 pid, uint256 amount) external {
        PoolInfo memory p = pools[pid];
        require(p.exists, "pool !exists");
        require(amount > 0, "amount=0");
        uint256 staked = userStake[msg.sender][pid];
        require(staked >= amount, "insufficient stake");
        // harvest pending before reducing stake
        uint256 rewards = pendingRewards(pid, msg.sender);
        if (rewards > 0) {
            p.rewardToken.transfer(msg.sender, rewards);
            emit Harvest(pid, msg.sender, rewards);
        }
        userStake[msg.sender][pid] = staked - amount;
        lastUpdate[msg.sender][pid] = block.timestamp;
        p.stakingToken.transfer(msg.sender, amount);
        emit Withdraw(pid, msg.sender, amount);
    }

    function harvest(uint256 pid) external {
        PoolInfo memory p = pools[pid];
        require(p.exists, "pool !exists");
        uint256 rewards = pendingRewards(pid, msg.sender);
        require(rewards > 0, "no rewards");
        lastUpdate[msg.sender][pid] = block.timestamp;
        p.rewardToken.transfer(msg.sender, rewards);
        emit Harvest(pid, msg.sender, rewards);
    }

    // Admin helpers to update rate or fund rewards
    function setRewardRate(uint256 pid, uint256 rate) external {
        require(pools[pid].exists, "pool !exists");
        pools[pid].rewardRatePerSecond = rate;
    }
}