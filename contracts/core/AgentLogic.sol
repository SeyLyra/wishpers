// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Vault.sol";
import "./MemoryContract.sol";

/**
 * @title AgentLogic
 * @notice Main operational AI agent contract - upgradeable, manages trading and learning
 */
contract AgentLogic is 
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    string public name;
    address public vault;
    address public memoryContract;
    address public strategyContract;

    struct TradeRequest {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 deadline;
        bool executed;
    }

    struct LearningState {
        uint256 totalTrades;
        uint256 successfulTrades;
        uint256 totalProfit;
        uint256 lastLearningUpdate;
        mapping(bytes32 => uint256) tradePatterns;
    }

    LearningState public learningState;
    TradeRequest[] public pendingTrades;
    
    mapping(address => bool) public allowedTokens;
    mapping(address => uint256) public maxPositionSize;
    
    uint256 public rebalanceThreshold; // Percentage (e.g., 10 = 10%)
    uint256 public minRebalanceInterval; // Seconds

    event TradeExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );
    event PortfolioRebalanced(
        address[] tokens,
        uint256[] newAllocations,
        uint256 timestamp
    );
    event LearningUpdate(
        bytes32 indexed pattern,
        uint256 weight,
        uint256 timestamp
    );
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        string memory _name,
        address _vault,
        address _memoryContract
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        name = _name;
        vault = _vault;
        memoryContract = _memoryContract;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);

        rebalanceThreshold = 10; // 10%
        minRebalanceInterval = 3600; // 1 hour
    }

    /**
     * @notice Execute a buy order
     */
    function buy(
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(block.timestamp <= deadline, "Trade expired");
        require(allowedTokens[tokenOut] || allowedTokens[address(0)], "Token not allowed");
        require(amountIn > 0, "Invalid amount");

        address tokenIn = Vault(vault).getBaseToken();
        
        uint256 amountOut = Vault(vault).swap(tokenIn, tokenOut, amountIn, minAmountOut);
        
        learningState.totalTrades++;
        
        emit TradeExecuted(tokenIn, tokenOut, amountIn, amountOut, block.timestamp);
        
        // Record learning pattern
        bytes32 pattern = keccak256(abi.encodePacked(tokenOut, block.timestamp / 86400));
        learningState.tradePatterns[pattern]++;
        
        // Update memory
        if (memoryContract != address(0)) {
            MemoryContract(memoryContract).recordTrade(
                address(this),
                tokenIn,
                tokenOut,
                amountIn,
                amountOut,
                true
            );
        }
    }

    /**
     * @notice Execute a sell order
     */
    function sell(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(block.timestamp <= deadline, "Trade expired");
        require(allowedTokens[tokenIn] || allowedTokens[address(0)], "Token not allowed");
        require(amountIn > 0, "Invalid amount");

        address tokenOut = Vault(vault).getBaseToken();
        
        uint256 amountOut = Vault(vault).swap(tokenIn, tokenOut, amountIn, minAmountOut);
        
        learningState.totalTrades++;
        
        emit TradeExecuted(tokenIn, tokenOut, amountIn, amountOut, block.timestamp);
        
        // Record learning pattern
        bytes32 pattern = keccak256(abi.encodePacked(tokenIn, block.timestamp / 86400));
        learningState.tradePatterns[pattern]++;
        
        // Update memory
        if (memoryContract != address(0)) {
            MemoryContract(memoryContract).recordTrade(
                address(this),
                tokenIn,
                tokenOut,
                amountIn,
                amountOut,
                false
            );
        }
    }

    /**
     * @notice Rebalance portfolio according to strategy
     */
    function rebalancePortfolio() external onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(
            block.timestamp >= learningState.lastLearningUpdate + minRebalanceInterval,
            "Rebalance cooldown active"
        );

        // Get current allocations from vault
        (address[] memory tokens, uint256[] memory currentAllocs) = Vault(vault).getPortfolioAllocations();
        
        // Calculate target allocations (would come from strategy contract)
        uint256[] memory targetAllocs = new uint256[](tokens.length);
        uint256 totalValue = Vault(vault).getTotalValue();
        
        // Simple example: equal allocation
        for (uint256 i = 0; i < tokens.length; i++) {
            targetAllocs[i] = 100 / tokens.length;
        }
        
        // Check if rebalancing is needed
        bool needsRebalance = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 currentPercent = (currentAllocs[i] * 100) / totalValue;
            if (
                currentPercent > targetAllocs[i] + rebalanceThreshold ||
                currentPercent < targetAllocs[i] - rebalanceThreshold
            ) {
                needsRebalance = true;
                break;
            }
        }
        
        if (needsRebalance) {
            // Execute rebalancing trades
            // Implementation would swap tokens to match target allocations
            learningState.lastLearningUpdate = block.timestamp;
            
            emit PortfolioRebalanced(tokens, targetAllocs, block.timestamp);
        }
    }

    /**
     * @notice Learn from trade outcomes and update weights
     */
    function learn(bytes32 pattern, uint256 profit) external onlyRole(OPERATOR_ROLE) {
        require(profit >= 0, "Invalid profit");
        
        learningState.tradePatterns[pattern]++;
        
        if (profit > 0) {
            learningState.successfulTrades++;
            learningState.totalProfit += profit;
        }
        
        learningState.lastLearningUpdate = block.timestamp;
        
        // Update memory contract
        if (memoryContract != address(0)) {
            MemoryContract(memoryContract).updateWeights(
                address(this),
                pattern,
                learningState.tradePatterns[pattern]
            );
        }
        
        emit LearningUpdate(pattern, learningState.tradePatterns[pattern], block.timestamp);
    }

    /**
     * @notice Set allowed tokens for trading
     */
    function setAllowedToken(address token, bool allowed, uint256 maxPosition) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        allowedTokens[token] = allowed;
        if (allowed) {
            maxPositionSize[token] = maxPosition;
        }
    }

    /**
     * @notice Set strategy contract
     */
    function setStrategyContract(address _strategyContract) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        address oldStrategy = strategyContract;
        strategyContract = _strategyContract;
        emit StrategyUpdated(oldStrategy, _strategyContract);
    }

    /**
     * @notice Update rebalancing parameters
     */
    function updateRebalanceParams(uint256 _threshold, uint256 _interval) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        rebalanceThreshold = _threshold;
        minRebalanceInterval = _interval;
    }

    /**
     * @notice Get learning statistics
     */
    function getLearningStats() external view returns (
        uint256 totalTrades,
        uint256 successfulTrades,
        uint256 totalProfit,
        uint256 lastUpdate
    ) {
        return (
            learningState.totalTrades,
            learningState.successfulTrades,
            learningState.totalProfit,
            learningState.lastLearningUpdate
        );
    }

    /**
     * @notice Get pattern weight
     */
    function getPatternWeight(bytes32 pattern) external view returns (uint256) {
        return learningState.tradePatterns[pattern];
    }

    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyRole(UPGRADER_ROLE) 
    {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}

