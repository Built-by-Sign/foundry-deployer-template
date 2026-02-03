// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployHelper} from "foundry-deployer/DeployHelper.sol";
import {ExampleContract} from "../src/ExampleContract.sol";

/**
 * @title Deploy
 * @notice Deployment script for ExampleContract using CREATE3
 * @dev Extends DeployHelper for deterministic deployment infrastructure
 */
contract Deploy is DeployHelper {
    string constant CATEGORY = "example";

    uint256 constant INITIAL_VALUE = 42;

    function setUp() public override {
        _setUp(CATEGORY);
    }

    function run() external {
        vm.startBroadcast(_deployer);

        address deployed = deploy(type(ExampleContract).creationCode);
        ExampleContract example = ExampleContract(deployed);

        // Check chain and transfer ownership on mainnet
        _checkChainAndSetOwner(address(example));

        // Save deployment artifacts
        _afterAll();

        vm.stopBroadcast();

        // Read-only verification (outside broadcast)
        require(example.value() == INITIAL_VALUE, "Initialization failed");
        require(keccak256(bytes(example.version())) == keccak256(bytes(example.VERSION())), "Version mismatch");
    }

    /// @dev Called by deploy() for atomic initialization to prevent frontrunning.
    function _getPostDeployInitData() internal view override returns (bytes memory) {
        return abi.encodeWithSignature("initialize(uint256,address)", INITIAL_VALUE, _deployer);
    }
}
