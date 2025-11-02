// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MemoryContract
 * @notice Stores agent state, learning weights, preferences - upgradeable storage
 */
contract MemoryContract is AccessControl, ReentrancyGuard {
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    struct TradeRecord {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 timestamp;
        bool isBuy;
        uint256 profit; // Calculated profit/loss
    }

    struct LearningWeights {
        bytes32 pattern;
        uint256 weight;
        uint256 lastUpdated;
        uint256 successCount;
        uint256 failureCount;
    }

    struct AgentState {
        uint256 totalTrades;
        uint256 totalProfit;
        uint256 totalLoss;
        uint256 lastTradeTimestamp;
        mapping(bytes32 => LearningWeights) weights;
        bytes32[] patternKeys;
    }

    mapping(address => AgentState) public agentStates;
    mapping(address => TradeRecord[]) public tradeHistory;
    mapping(address => mapping(string => bytes)) public preferences; // Custom preferences storage

    event TradeRecorded(
        address indexed agent,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bool isBuy
    );
    event WeightsUpdated(
        address indexed agent,
        bytes32 indexed pattern,
        uint256 newWeight,
        uint256 successCount,
        uint256 failureCount
    );
    event PreferenceSet(address indexed agent, string key, bytes value);
    event StateLoaded(address indexed agent, uint256 totalTrades, uint256 totalProfit);
    event StateSaved(address indexed agent, uint256 totalTrades, uint256 totalProfit);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Record a trade
     */
    function recordTrade(
        address agent,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bool isBuy
    ) external onlyRole(AGENT_ROLE) nonReentrant {
        require(agent != address(0), "Invalid agent");

        int256 profit = isBuy ? 
            int256(amountOut) - int256(amountIn) :
            int256(amountOut) - int256(amountIn);
        // Store only aggregated counters on-chain; rely on events for full history
        
        AgentState storage state = agentStates[agent];
        state.totalTrades++;
        state.lastTradeTimestamp = block.timestamp;

        if (profit > 0) {
            state.totalProfit += uint256(profit);
        } else {
            state.totalLoss += uint256(-profit);
        }

        emit TradeRecorded(agent, tokenIn, tokenOut, amountIn, amountOut, isBuy);
    }

    /**
     * @notice Update learning weights
     */
    function updateWeights(
        address agent,
        bytes32 pattern,
        uint256 weight
    ) external onlyRole(AGENT_ROLE) nonReentrant {
        require(agent != address(0), "Invalid agent");

        AgentState storage state = agentStates[agent];
        LearningWeights storage weights = state.weights[pattern];

        if (weights.pattern == bytes32(0)) {
            // New pattern
            weights.pattern = pattern;
            state.patternKeys.push(pattern);
        }

        // Determine if last trade was successful (simplified)
        bool isSuccess = weight > weights.weight;
        
        if (isSuccess) {
            weights.successCount++;
        } else {
            weights.failureCount++;
        }

        weights.weight = weight;
        weights.lastUpdated = block.timestamp;

        emit WeightsUpdated(agent, pattern, weight, weights.successCount, weights.failureCount);
    }

    /**
     * @notice Save agent state
     */
    function saveState(address agent) external onlyRole(AGENT_ROLE) {
        AgentState storage state = agentStates[agent];
        emit StateSaved(agent, state.totalTrades, state.totalProfit);
    }

    /**
     * @notice Load agent state (returns key metrics)
     */
    function loadState(address agent) 
        external 
        view 
        returns (
            uint256 totalTrades,
            uint256 totalProfit,
            uint256 totalLoss,
            uint256 lastTradeTimestamp
        ) 
    {
        AgentState storage state = agentStates[agent];
        return (
            state.totalTrades,
            state.totalProfit,
            state.totalLoss,
            state.lastTradeTimestamp
        );
    }

    /**
     * @notice Get learning weight for a pattern
     */
    function getWeight(address agent, bytes32 pattern) 
        external 
        view 
        returns (
            uint256 weight,
            uint256 successCount,
            uint256 failureCount,
            uint256 lastUpdated
        ) 
    {
        LearningWeights storage weights = agentStates[agent].weights[pattern];
        return (
            weights.weight,
            weights.successCount,
            weights.failureCount,
            weights.lastUpdated
        );
    }

    /**
     * @notice Get all patterns for an agent
     */
    function getPatterns(address agent) external view returns (bytes32[] memory) {
        return agentStates[agent].patternKeys;
    }

    /**
     * @notice Get trade history
     */
    function getTradeHistory(address agent, uint256 limit) 
        external 
        view 
        returns (TradeRecord[] memory) 
    {
        TradeRecord[] memory history = tradeHistory[agent];
        uint256 length = history.length;
        
        if (limit == 0 || limit > length) {
            limit = length;
        }
        
        TradeRecord[] memory result = new TradeRecord[](limit);
        uint256 start = length > limit ? length - limit : 0;
        
        for (uint256 i = 0; i < limit && start + i < length; i++) {
            result[i] = history[start + i];
        }
        
        return result;
    }

    /**
     * @notice Set preference
     */
    function setPreference(
        address agent,
        string memory key,
        bytes memory value
    ) external onlyRole(AGENT_ROLE) {
        preferences[agent][key] = value;
        emit PreferenceSet(agent, key, value);
    }

    /**
     * @notice Get preference
     */
    function getPreference(address agent, string memory key) 
        external 
        view 
        returns (bytes memory) 
    {
        return preferences[agent][key];
    }

    // Lightweight IPFS learning anchor
    event LearningAnchorRecorded(address indexed agent, bytes32 contentHash, string cid);
    mapping(address => bytes32) public latestLearningContentHash;

    function recordLearningAnchor(
        address agent,
        bytes32 contentHash,
        string calldata cid
    ) external onlyRole(AGENT_ROLE) {
        require(agent != address(0), "Invalid agent");
        latestLearningContentHash[agent] = contentHash;
        emit LearningAnchorRecorded(agent, contentHash, cid);
    }

    /**
     * @notice Grant agent role
     */
    function grantAgentRole(address agent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(AGENT_ROLE, agent);
    }

    /**
     * @notice Get agent statistics
     */
    function getAgentStats(address agent) 
        external 
        view 
        returns (
            uint256 totalTrades,
            uint256 totalProfit,
            uint256 totalLoss,
            uint256 winRate,
            uint256 patternCount
        ) 
    {
        AgentState storage state = agentStates[agent];
        totalTrades = state.totalTrades;
        totalProfit = state.totalProfit;
        totalLoss = state.totalLoss;
        patternCount = state.patternKeys.length;
        
        if (state.totalTrades > 0) {
            uint256 successful = state.totalProfit > 0 ? 
                (state.totalProfit * 100) / (state.totalProfit + state.totalLoss) : 0;
            winRate = successful;
        }
    }
}

