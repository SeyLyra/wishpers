// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IAssetAdapter.sol";

/**
 * @title SomniaAdapterRegistry
 * @notice Registry to manage all Somnia protocol adapters
 */
contract SomniaAdapterRegistry is AccessControl {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    enum AdapterType {
        Swap,
        Lending,
        Staking
    }

    struct AdapterInfo {
        address adapterAddress;
        AdapterType adapterType;
        string name;
        bool active;
        uint256 registeredAt;
    }

    mapping(address => AdapterInfo) public adapters;
    mapping(AdapterType => address[]) public adaptersByType;
    mapping(address => AdapterType) public tokenPreferredAdapter; // Token => preferred adapter type
    
    address[] public allAdapters;

    event AdapterRegistered(
        address indexed adapter,
        AdapterType adapterType,
        string name
    );
    event AdapterDeactivated(address indexed adapter);
    event AdapterActivated(address indexed adapter);
    event PreferredAdapterSet(address indexed token, AdapterType adapterType);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
    }

    /**
     * @notice Register a new adapter
     */
    function registerAdapter(
        address adapter,
        AdapterType adapterType,
        string memory name
    ) external onlyRole(REGISTRAR_ROLE) {
        require(adapter != address(0), "Invalid adapter");
        require(adapters[adapter].adapterAddress == address(0), "Already registered");
        
        // Verify adapter implements IAssetAdapter
        try IAssetAdapter(adapter).adapterName() returns (string memory) {
            // Valid adapter
        } catch {
            revert("Invalid adapter interface");
        }

        adapters[adapter] = AdapterInfo({
            adapterAddress: adapter,
            adapterType: adapterType,
            name: name,
            active: true,
            registeredAt: block.timestamp
        });

        adaptersByType[adapterType].push(adapter);
        allAdapters.push(adapter);

        emit AdapterRegistered(adapter, adapterType, name);
    }

    /**
     * @notice Set preferred adapter type for a token
     */
    function setPreferredAdapter(
        address token,
        AdapterType adapterType
    ) external onlyRole(REGISTRAR_ROLE) {
        tokenPreferredAdapter[token] = adapterType;
        emit PreferredAdapterSet(token, adapterType);
    }

    /**
     * @notice Get best adapter for a token pair
     */
    function getBestAdapter(
        address tokenIn,
        address tokenOut
    ) external view returns (address) {
        // Check preferred adapter for tokenIn
        AdapterType preferred = tokenPreferredAdapter[tokenIn];
        address[] memory typeAdapters = adaptersByType[preferred];
        
        // Try preferred adapter type first
        for (uint256 i = 0; i < typeAdapters.length; i++) {
            AdapterInfo memory info = adapters[typeAdapters[i]];
            if (info.active) {
                try IAssetAdapter(info.adapterAddress).supportsPair(tokenIn, tokenOut) returns (bool supported) {
                    if (supported) {
                        return info.adapterAddress;
                    }
                } catch {
                    continue;
                }
            }
        }
        
        // Fallback: try all adapters
        for (uint256 i = 0; i < allAdapters.length; i++) {
            AdapterInfo memory info = adapters[allAdapters[i]];
            if (info.active) {
                try IAssetAdapter(info.adapterAddress).supportsPair(tokenIn, tokenOut) returns (bool supported) {
                    if (supported) {
                        return info.adapterAddress;
                    }
                } catch {
                    continue;
                }
            }
        }
        
        return address(0); // No adapter found
    }

    /**
     * @notice Get all adapters of a type
     */
    function getAdaptersByType(AdapterType adapterType) 
        external 
        view 
        returns (address[] memory) 
    {
        return adaptersByType[adapterType];
    }

    /**
     * @notice Deactivate adapter
     */
    function deactivateAdapter(address adapter) 
        external 
        onlyRole(REGISTRAR_ROLE) 
    {
        require(adapters[adapter].adapterAddress != address(0), "Not registered");
        adapters[adapter].active = false;
        emit AdapterDeactivated(adapter);
    }

    /**
     * @notice Activate adapter
     */
    function activateAdapter(address adapter) 
        external 
        onlyRole(REGISTRAR_ROLE) 
    {
        require(adapters[adapter].adapterAddress != address(0), "Not registered");
        adapters[adapter].active = true;
        emit AdapterActivated(adapter);
    }

    /**
     * @notice Get adapter info
     */
    function getAdapterInfo(address adapter) 
        external 
        view 
        returns (AdapterInfo memory) 
    {
        return adapters[adapter];
    }

    /**
     * @notice Get total adapter count
     */
    function getTotalAdapters() external view returns (uint256) {
        return allAdapters.length;
    }
}

