// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title Governance
 * @notice Governance contract for community voting on upgrades and proposals
 */
contract Governance is 
    Governor,
    GovernorSettings,
    GovernorTimelockControl,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorCountingSimple
{
    struct UpgradeProposal {
        address targetContract;
        address newImplementation;
        string description;
        uint256 proposalId;
    }

    mapping(uint256 => UpgradeProposal) public upgradeProposals;

    event UpgradeProposed(
        uint256 indexed proposalId,
        address indexed targetContract,
        address indexed newImplementation
    );
    event UpgradeExecuted(
        uint256 indexed proposalId,
        address indexed targetContract,
        address indexed newImplementation
    );

    constructor(
        ERC20Votes _token,
        TimelockController _timelock,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumPercentage
    )
        Governor("Wishpers Governance")
        GovernorSettings(_votingDelay, _votingPeriod, _proposalThreshold)
        GovernorTimelockControl(_timelock)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumPercentage)
    {}

    // Override required functions
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposeUpgrade(
        address targetContract,
        address newImplementation,
        string memory description
    ) external returns (uint256) {
        require(targetContract != address(0), "Invalid target");
        require(newImplementation != address(0), "Invalid implementation");

        bytes memory upgradeCalldata = abi.encodeWithSignature(
            "upgrade(address,address)",
            targetContract,
            newImplementation
        );

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = targetContract;
        values[0] = 0;
        calldatas[0] = upgradeCalldata;

        uint256 proposalId = this.propose(targets, values, calldatas, description);

        upgradeProposals[proposalId] = UpgradeProposal({
            targetContract: targetContract,
            newImplementation: newImplementation,
            description: description,
            proposalId: proposalId
        });

        emit UpgradeProposed(proposalId, targetContract, newImplementation);

        return proposalId;
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);

        if (upgradeProposals[proposalId].targetContract != address(0)) {
            UpgradeProposal memory proposal = upgradeProposals[proposalId];
            emit UpgradeExecuted(
                proposalId,
                proposal.targetContract,
                proposal.newImplementation
            );
        }
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}

