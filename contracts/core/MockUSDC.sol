// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDC
 * @dev ERC20 token with 6 decimals (like real USDC) and faucet functionality
 */
contract MockUSDC is ERC20, Ownable {
    uint8 private constant DECIMALS = 6;

    // Faucet configuration
    uint256 public faucetAmount;
    uint256 public cooldownTime;

    // Track last faucet claim per address
    mapping(address => uint256) public lastClaim;

    event FaucetClaim(address indexed recipient, uint256 amount);
    event FaucetConfigUpdated(uint256 amount, uint256 cooldown);

    /**
     * @dev Constructor
     * @param _faucetAmount Amount to give per faucet claim (in USDC units, e.g., 1000 = 1000 USDC)
     * @param _cooldownTime Cooldown between claims in seconds
     */
    constructor(
        uint256 _faucetAmount,
        uint256 _cooldownTime
    ) ERC20("Mock USDC", "USDC") Ownable() {
        // Convert faucet amount to 6 decimals (e.g., 1000 USDC = 1000 * 10^6)
        faucetAmount = _faucetAmount * (10 ** DECIMALS);
        cooldownTime = _cooldownTime;

        // Mint initial supply to deployer (1 million USDC)
        _mint(msg.sender, 1_000_000 * (10 ** DECIMALS));
    }

    /**
     * @dev Override decimals to return 6 (like real USDC)
     */
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Claim tokens from faucet
     */
    function claim() external {
        require(
            block.timestamp >= lastClaim[msg.sender] + cooldownTime,
            "MockUSDC: Cooldown period not elapsed"
        );

        lastClaim[msg.sender] = block.timestamp;
        _mint(msg.sender, faucetAmount);

        emit FaucetClaim(msg.sender, faucetAmount);
    }

    /**
     * @dev Claim tokens for another address (useful for server-side faucet)
     */
    function claimFor(address recipient) external {
        require(recipient != address(0), "MockUSDC: Zero address");
        require(
            block.timestamp >= lastClaim[recipient] + cooldownTime,
            "MockUSDC: Cooldown period not elapsed"
        );

        lastClaim[recipient] = block.timestamp;
        _mint(recipient, faucetAmount);

        emit FaucetClaim(recipient, faucetAmount);
    }

    /**
     * @dev Check if an address can claim
     */
    function canClaim(address user) external view returns (bool, uint256) {
        uint256 nextClaimTime = lastClaim[user] + cooldownTime;
        if (block.timestamp >= nextClaimTime) {
            return (true, 0);
        } else {
            return (false, nextClaimTime - block.timestamp);
        }
    }

    /**
     * @dev Update faucet configuration (owner only)
     */
    function updateFaucetConfig(uint256 _faucetAmount, uint256 _cooldownTime)
        external
        onlyOwner
    {
        faucetAmount = _faucetAmount * (10 ** DECIMALS);
        cooldownTime = _cooldownTime;
        emit FaucetConfigUpdated(faucetAmount, cooldownTime);
    }

    /**
     * @dev Mint tokens to an address (owner only, for testing)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
