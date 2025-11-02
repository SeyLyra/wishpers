// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./AgentRegistry.sol";
import "./AgentLogic.sol";

/**
 * @title AgentFactory
 * @notice Factory contract for deploying new AI agent instances
 */
contract AgentFactory is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    AgentRegistry public registry;
    address public implementation;
    
    mapping(address => address[]) public userAgents;
    
    event AgentDeployed(
        address indexed agentAddress,
        address indexed owner,
        string metadataURI
    );

    constructor(address _registry, address _implementation) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEPLOYER_ROLE, msg.sender);
        
        registry = AgentRegistry(_registry);
        implementation = _implementation;
    }

    /**
     * @notice Deploy a new agent instance
     */
    function deployAgent(
        address owner,
        string memory name,
        string memory metadataURI,
        address vaultAddress,
        address memoryContract
    ) external onlyRole(DEPLOYER_ROLE) returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            AgentLogic.initialize.selector,
            owner,
            name,
            vaultAddress,
            memoryContract
        );

        ERC1967Proxy proxy = new ERC1967Proxy(implementation, initData);
        address agentAddress = address(proxy);

        // Register in registry
        registry.registerAgent(agentAddress, owner, metadataURI);
        
        // Track user agents
        userAgents[owner].push(agentAddress);

        emit AgentDeployed(agentAddress, owner, metadataURI);
        
        return agentAddress;
    }

    /**
     * @notice Set new implementation for upgrades
     */
    function setImplementation(address _implementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        implementation = _implementation;
    }

    /**
     * @notice Get all agents for a user
     */
    function getUserAgents(address user) external view returns (address[] memory) {
        return userAgents[user];
    }
}

