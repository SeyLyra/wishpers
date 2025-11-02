// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Vault.sol";
import "./AgentLogic.sol";

/**
 * @title Strategy
 * @notice Defines trading and rebalancing logic - swappable/upgradeable
 */
contract Strategy is AccessControl, ReentrancyGuard {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    struct Allocation {
        address token;
        uint256 targetPercentage; // Basis points (10000 = 100%)
        uint256 minPercentage;
        uint256 maxPercentage;
    }

    mapping(address => Allocation) public allocations;
    address[] public targetTokens;
    
    address public vault;
    address public agent;
    
    uint256 public rebalanceThreshold; // Basis points
    uint256 public maxSlippage; // Basis points
    
    bool public paused;

    event StrategyUpdated(address indexed token, uint256 targetPercent, uint256 minPercent, uint256 maxPercent);
    event RebalanceExecuted(address[] tokens, uint256[] newAllocations);
    event StrategyPaused(bool paused);

    constructor(address _vault) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
        
        vault = _vault;
        rebalanceThreshold = 500; // 5%
        maxSlippage = 300; // 3%
    }

    /**
     * @notice Set target allocation for a token
     */
    function setAllocation(
        address token,
        uint256 targetPercent,
        uint256 minPercent,
        uint256 maxPercent
    ) external onlyRole(UPDATER_ROLE) {
        require(targetPercent <= 10000, "Invalid percentage");
        require(minPercent <= targetPercent && targetPercent <= maxPercent, "Invalid range");
        
        if (allocations[token].token == address(0)) {
            targetTokens.push(token);
        }
        
        allocations[token] = Allocation({
            token: token,
            targetPercentage: targetPercent,
            minPercentage: minPercent,
            maxPercentage: maxPercent
        });
        
        emit StrategyUpdated(token, targetPercent, minPercent, maxPercent);
    }

    /**
     * @notice Calculate target allocations based on current portfolio
     */
    function calculateTargetAllocations() 
        external 
        view 
        returns (address[] memory tokens, uint256[] memory targetAmounts) 
    {
        uint256 totalValue = Vault(vault).getTotalValue();
        uint256 length = targetTokens.length;
        
        tokens = new address[](length);
        targetAmounts = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            address token = targetTokens[i];
            Allocation memory alloc = allocations[token];
            
            tokens[i] = token;
            targetAmounts[i] = (totalValue * alloc.targetPercentage) / 10000;
        }
    }

    /**
     * @notice Check if rebalancing is needed
     */
    function needsRebalance() external view returns (bool) {
        (address[] memory tokens, uint256[] memory currentAmounts) = Vault(vault).getPortfolioAllocations();
        uint256 totalValue = Vault(vault).getTotalValue();
        
        if (totalValue == 0) return false;
        
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            Allocation memory alloc = allocations[token];
            
            if (alloc.token == address(0)) continue;
            
            uint256 currentPercent = (currentAmounts[i] * 10000) / totalValue;
            
            if (
                currentPercent < alloc.minPercentage ||
                currentPercent > alloc.maxPercentage ||
                (currentPercent > alloc.targetPercentage && 
                 currentPercent - alloc.targetPercentage > rebalanceThreshold) ||
                (currentPercent < alloc.targetPercentage && 
                 alloc.targetPercentage - currentPercent > rebalanceThreshold)
            ) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * @notice Generate rebalance instructions
     */
    function generateRebalanceInstructions() 
        external 
        view 
        returns (
            address[] memory tokensToSell,
            uint256[] memory amountsToSell,
            address[] memory tokensToBuy,
            uint256[] memory amountsToBuy
        ) 
    {
        (address[] memory currentTokens, uint256[] memory currentAmounts) = 
            Vault(vault).getPortfolioAllocations();
        
        uint256 totalValue = Vault(vault).getTotalValue();
        
        // This is simplified - in production would need more complex logic
        // For now, return empty arrays as placeholder
        tokensToSell = new address[](0);
        amountsToSell = new uint256[](0);
        tokensToBuy = new address[](0);
        amountsToBuy = new uint256[](0);
    }

    /**
     * @notice Set rebalance threshold
     */
    function setRebalanceThreshold(uint256 _threshold) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_threshold <= 10000, "Invalid threshold");
        rebalanceThreshold = _threshold;
    }

    /**
     * @notice Set max slippage
     */
    function setMaxSlippage(uint256 _slippage) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_slippage <= 10000, "Invalid slippage");
        maxSlippage = _slippage;
    }

    /**
     * @notice Link agent contract
     */
    function setAgent(address _agent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        agent = _agent;
    }

    /**
     * @notice Pause strategy
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = true;
        emit StrategyPaused(true);
    }

    /**
     * @notice Unpause strategy
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = false;
        emit StrategyPaused(false);
    }

    /**
     * @notice Get allocation for token
     */
    function getAllocation(address token) external view returns (Allocation memory) {
        return allocations[token];
    }

    modifier whenNotPaused() {
        require(!paused, "Strategy paused");
        _;
    }
}

