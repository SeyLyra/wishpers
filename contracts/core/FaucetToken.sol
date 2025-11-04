// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FaucetToken
 * @dev ERC20 token with public faucet functionality for testing
 * Anyone can mint tokens, but with a cooldown period to prevent abuse
 */
contract FaucetToken is ERC20, Ownable {
    // Faucet configuration
    uint256 public faucetAmount;
    uint256 public cooldownTime;

    // Track last faucet claim per address
    mapping(address => uint256) public lastClaim;

    event FaucetClaim(address indexed recipient, uint256 amount);
    event FaucetConfigUpdated(uint256 amount, uint256 cooldown);

    /**
     * @dev Constructor
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param _faucetAmount Amount to give per faucet claim (in wei, e.g., 1000 ether)
     * @param _cooldownTime Cooldown between claims in seconds (e.g., 86400 for 24 hours)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _faucetAmount,
        uint256 _cooldownTime
    ) ERC20(name_, symbol_) Ownable() {
        faucetAmount = _faucetAmount;
        cooldownTime = _cooldownTime;

        // Mint initial supply to deployer for manual distribution if needed
        _mint(msg.sender, 1000000 ether);
    }

    /**
     * @dev Claim tokens from faucet
     * Anyone can call this, but must wait for cooldown period
     */
    function claim() external {
        require(
            block.timestamp >= lastClaim[msg.sender] + cooldownTime,
            "FaucetToken: Cooldown period not elapsed"
        );

        lastClaim[msg.sender] = block.timestamp;
        _mint(msg.sender, faucetAmount);

        emit FaucetClaim(msg.sender, faucetAmount);
    }

    /**
     * @dev Claim tokens for a specific address (useful for backend faucet)
     * @param recipient Address to receive tokens
     */
    function claimFor(address recipient) external {
        require(recipient != address(0), "FaucetToken: Zero address");
        require(
            block.timestamp >= lastClaim[recipient] + cooldownTime,
            "FaucetToken: Cooldown period not elapsed"
        );

        lastClaim[recipient] = block.timestamp;
        _mint(recipient, faucetAmount);

        emit FaucetClaim(recipient, faucetAmount);
    }

    /**
     * @dev Owner can mint tokens directly (bypass faucet limits)
     * @param to Address to receive tokens
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Update faucet configuration
     * @param _faucetAmount New faucet amount
     * @param _cooldownTime New cooldown time
     */
    function updateFaucetConfig(uint256 _faucetAmount, uint256 _cooldownTime) external onlyOwner {
        faucetAmount = _faucetAmount;
        cooldownTime = _cooldownTime;

        emit FaucetConfigUpdated(_faucetAmount, _cooldownTime);
    }

    /**
     * @dev Check if an address can claim from faucet
     * @param account Address to check
     * @return canClaim Whether the address can claim
     * @return timeUntilNext Seconds until next claim is available
     */
    function canClaim(address account) external view returns (bool canClaim, uint256 timeUntilNext) {
        uint256 nextClaimTime = lastClaim[account] + cooldownTime;

        if (block.timestamp >= nextClaimTime) {
            return (true, 0);
        } else {
            return (false, nextClaimTime - block.timestamp);
        }
    }
}
