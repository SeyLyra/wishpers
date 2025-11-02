// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAssetAdapter.sol";

/**
 * @title Vault
 * @notice Manages portfolio assets, tracks allocations, handles swaps and rebalancing
 */
contract Vault is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public baseToken; // USDC, USDT, etc.
    address[] public trackedTokens;
    
    mapping(address => bool) public isTrackedToken;
    mapping(address => uint256) public balances;
    mapping(address => IAssetAdapter) public adapters;
    
    uint256 public totalDeposited;
    uint256 public totalWithdrawn;
    
    struct PortfolioSnapshot {
        address[] tokens;
        uint256[] amounts;
        uint256 timestamp;
    }
    
    PortfolioSnapshot[] public snapshots;
    uint256 public snapshotInterval; // Seconds between snapshots

    event Deposit(address indexed token, uint256 amount, address indexed depositor);
    event Withdraw(address indexed token, uint256 amount, address indexed recipient);
    event Swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed swapper
    );
    event Rebalance(address[] tokens, uint256[] newAmounts);
    event SnapshotCreated(uint256 indexed snapshotId, address[] tokens, uint256[] amounts);
    event AdapterSet(address indexed token, address indexed adapter);

    constructor(address _baseToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        
        baseToken = _baseToken;
        trackedTokens.push(_baseToken);
        isTrackedToken[_baseToken] = true;
        snapshotInterval = 3600; // 1 hour
    }

    /**
     * @notice Deposit tokens into vault
     */
    function deposit(address token, uint256 amount) 
        external 
        nonReentrant 
    {
        require(amount > 0, "Invalid amount");
        require(isTrackedToken[token] || hasRole(MANAGER_ROLE, msg.sender), "Token not tracked");
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        balances[token] += amount;
        totalDeposited += amount;
        
        if (!isTrackedToken[token]) {
            trackedTokens.push(token);
            isTrackedToken[token] = true;
        }
        
        emit Deposit(token, amount, msg.sender);
    }

    /**
     * @notice Withdraw tokens from vault
     */
    function withdraw(address token, uint256 amount, address recipient) 
        external 
        onlyRole(AGENT_ROLE) 
        nonReentrant 
    {
        require(amount > 0, "Invalid amount");
        require(balances[token] >= amount, "Insufficient balance");
        require(recipient != address(0), "Invalid recipient");
        
        balances[token] -= amount;
        totalWithdrawn += amount;
        
        IERC20(token).safeTransfer(recipient, amount);
        
        emit Withdraw(token, amount, recipient);
    }

    /**
     * @notice Execute swap through adapter
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external onlyRole(AGENT_ROLE) nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid amount");
        require(balances[tokenIn] >= amountIn, "Insufficient balance");
        require(isTrackedToken[tokenIn], "TokenIn not tracked");
        require(isTrackedToken[tokenOut], "TokenOut not tracked");
        
        balances[tokenIn] -= amountIn;
        
        // Use adapter if available, otherwise direct transfer
        if (address(adapters[tokenIn]) != address(0)) {
            IERC20(tokenIn).safeIncreaseAllowance(address(adapters[tokenIn]), amountIn);
            amountOut = adapters[tokenIn].swap(tokenIn, tokenOut, amountIn, minAmountOut);
            // Reset allowance to 0 for security
            uint256 currentAllowance = IERC20(tokenIn).allowance(address(this), address(adapters[tokenIn]));
            if (currentAllowance > 0) {
                IERC20(tokenIn).safeDecreaseAllowance(address(adapters[tokenIn]), currentAllowance);
            }
        } else {
            // Simple transfer (for testing)
            IERC20(tokenOut).safeTransferFrom(address(this), address(this), amountIn);
            amountOut = amountIn; // Simplified
        }
        
        require(amountOut >= minAmountOut, "Slippage too high");
        
        balances[tokenOut] += amountOut;
        
        emit Swap(tokenIn, tokenOut, amountIn, amountOut, msg.sender);
        
        return amountOut;
    }

    /**
     * @notice Get portfolio allocations
     */
    function getPortfolioAllocations() 
        external 
        view 
        returns (address[] memory tokens, uint256[] memory amounts) 
    {
        uint256 length = trackedTokens.length;
        tokens = new address[](length);
        amounts = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = trackedTokens[i];
            amounts[i] = balances[trackedTokens[i]];
        }
    }

    /**
     * @notice Get total portfolio value in base token
     */
    function getTotalValue() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < trackedTokens.length; i++) {
            address token = trackedTokens[i];
            if (token == baseToken) {
                total += balances[token];
            } else {
                // Get price from adapter or oracle
                if (address(adapters[token]) != address(0)) {
                    total += adapters[token].getValueInBaseToken(token, balances[token]);
                } else {
                    // Fallback to 1:1 if no adapter
                    total += balances[token];
                }
            }
        }
        return total;
    }

    /**
     * @notice Create portfolio snapshot
     */
    function createSnapshot() external onlyRole(MANAGER_ROLE) {
        (address[] memory tokens, uint256[] memory amounts) = this.getPortfolioAllocations();
        
        snapshots.push(PortfolioSnapshot({
            tokens: tokens,
            amounts: amounts,
            timestamp: block.timestamp
        }));
        
        emit SnapshotCreated(snapshots.length - 1, tokens, amounts);
    }

    /**
     * @notice Set adapter for a token
     */
    function setAdapter(address token, IAssetAdapter adapter) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(address(adapter) != address(0), "Invalid adapter");
        adapters[token] = adapter;
        emit AdapterSet(token, address(adapter));
    }

    /**
     * @notice Add tracked token
     */
    function addTrackedToken(address token) external onlyRole(MANAGER_ROLE) {
        require(!isTrackedToken[token], "Token already tracked");
        trackedTokens.push(token);
        isTrackedToken[token] = true;
    }

    /**
     * @notice Grant agent role to agent contract
     */
    function grantAgentRole(address agent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(AGENT_ROLE, agent);
    }

    /**
     * @notice Get base token address
     */
    function getBaseToken() external view returns (address) {
        return baseToken;
    }

    /**
     * @notice Get balance of a token
     */
    function getBalance(address token) external view returns (uint256) {
        return balances[token];
    }

    /**
     * @notice Get number of tracked tokens
     */
    function getTrackedTokenCount() external view returns (uint256) {
        return trackedTokens.length;
    }
}

