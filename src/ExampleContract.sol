// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "solady/auth/Ownable.sol";
import {Initializable} from "solady/utils/Initializable.sol";
import {IVersionable} from "foundry-deployer/interfaces/IVersionable.sol";

/**
 * @title ExampleContract
 * @notice A minimal example contract demonstrating the foundry-deployer pattern
 * @dev Implements IVersionable for deployment tracking and extends Ownable for access control
 */
contract ExampleContract is Ownable, Initializable, IVersionable {
    /// @dev Format: "{major}.{minor}.{patch}-{ContractName}"
    string public constant VERSION = "1.0.0-ExampleContract";

    uint256 public value;

    event ValueUpdated(uint256 oldValue, uint256 newValue);

    /**
     * @notice Initialize the contract with an initial value
     * @param _initialValue The starting value for the contract
     * @param _owner The address that will own this contract
     */
    function initialize(uint256 _initialValue, address _owner) external initializer {
        _initializeOwner(_owner);
        value = _initialValue;
        emit ValueUpdated(0, _initialValue);
    }

    /**
     * @notice Update the stored value (only owner)
     * @param _newValue The new value to store
     */
    function setValue(uint256 _newValue) external onlyOwner {
        uint256 oldValue = value;
        value = _newValue;
        emit ValueUpdated(oldValue, _newValue);
    }

    function version() external pure override returns (string memory) {
        return VERSION;
    }
}
