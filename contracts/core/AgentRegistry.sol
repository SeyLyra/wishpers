// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AgentRegistry
 * @notice Registry for managing AI agent deployments, versions, and ownership
 */
contract AgentRegistry is AccessControl, ReentrancyGuard {
    bytes32 public constant AGENT_FACTORY_ROLE = keccak256("AGENT_FACTORY_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct Agent {
        address agentAddress;
        address owner;
        uint256 version;
        uint256 createdAt;
        bool active;
        string metadataURI;
    }

    mapping(address => Agent) public agents;
    mapping(address => address[]) public ownerAgents;
    mapping(uint256 => address) public versionRegistry;
    
    address[] public allAgents;
    uint256 public totalAgents;
    uint256 public currentVersion;

    event AgentRegistered(
        address indexed agentAddress,
        address indexed owner,
        uint256 version,
        string metadataURI
    );
    event AgentUpdated(
        address indexed agentAddress,
        uint256 newVersion,
        string newMetadataURI
    );
    event AgentDeactivated(address indexed agentAddress);
    event AgentActivated(address indexed agentAddress);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AGENT_FACTORY_ROLE, msg.sender);
    }

    /**
     * @notice Register a new agent
     */
    function registerAgent(
        address agentAddress,
        address owner,
        string memory metadataURI
    ) external onlyRole(AGENT_FACTORY_ROLE) nonReentrant {
        require(agentAddress != address(0), "Invalid agent address");
        require(agents[agentAddress].agentAddress == address(0), "Agent already registered");

        currentVersion++;
        
        agents[agentAddress] = Agent({
            agentAddress: agentAddress,
            owner: owner,
            version: currentVersion,
            createdAt: block.timestamp,
            active: true,
            metadataURI: metadataURI
        });

        ownerAgents[owner].push(agentAddress);
        allAgents.push(agentAddress);
        versionRegistry[currentVersion] = agentAddress;
        totalAgents++;

        emit AgentRegistered(agentAddress, owner, currentVersion, metadataURI);
    }

    /**
     * @notice Update agent to new version
     */
    function updateAgentVersion(
        address agentAddress,
        address newAgentAddress,
        string memory newMetadataURI
    ) external onlyRole(UPGRADER_ROLE) nonReentrant {
        require(agents[agentAddress].agentAddress != address(0), "Agent not registered");
        require(newAgentAddress != address(0), "Invalid new agent address");

        Agent storage agent = agents[agentAddress];
        agent.active = false;

        currentVersion++;
        
        agents[newAgentAddress] = Agent({
            agentAddress: newAgentAddress,
            owner: agent.owner,
            version: currentVersion,
            createdAt: block.timestamp,
            active: true,
            metadataURI: newMetadataURI
        });

        ownerAgents[agent.owner].push(newAgentAddress);
        allAgents.push(newAgentAddress);
        versionRegistry[currentVersion] = newAgentAddress;
        totalAgents++;

        emit AgentUpdated(newAgentAddress, currentVersion, newMetadataURI);
        emit AgentDeactivated(agentAddress);
        emit AgentActivated(newAgentAddress);
    }

    /**
     * @notice Deactivate an agent
     */
    function deactivateAgent(address agentAddress) external onlyRole(UPGRADER_ROLE) {
        require(agents[agentAddress].agentAddress != address(0), "Agent not registered");
        agents[agentAddress].active = false;
        emit AgentDeactivated(agentAddress);
    }

    /**
     * @notice Activate an agent
     */
    function activateAgent(address agentAddress) external onlyRole(UPGRADER_ROLE) {
        require(agents[agentAddress].agentAddress != address(0), "Agent not registered");
        agents[agentAddress].active = true;
        emit AgentActivated(agentAddress);
    }

    /**
     * @notice Get agent information
     */
    function getAgent(address agentAddress) external view returns (Agent memory) {
        return agents[agentAddress];
    }

    /**
     * @notice Get all agents owned by an address
     */
    function getOwnerAgents(address owner) external view returns (address[] memory) {
        return ownerAgents[owner];
    }

    /**
     * @notice Get agent by version
     */
    function getAgentByVersion(uint256 version) external view returns (address) {
        return versionRegistry[version];
    }

    /**
     * @notice Get total number of agents
     */
    function getTotalAgents() external view returns (uint256) {
        return totalAgents;
    }
}

