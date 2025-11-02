// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStrategy
 * @notice Interface for strategy contracts
 */
interface IStrategy {
    struct Allocation {
        address token;
        uint256 targetPercentage;
        uint256 minPercentage;
        uint256 maxPercentage;
    }

    function calculateTargetAllocations() 
        external 
        view 
        returns (address[] memory tokens, uint256[] memory targetAmounts);

    function needsRebalance() external view returns (bool);

    function getAllocation(address token) 
        external 
        view 
        returns (Allocation memory);
}

