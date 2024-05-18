// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IQWChild} from 'interfaces/IQWChild.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';

/**
 * @title Quant Wealth Registry Contract
 * @notice This contract manages the registration of child contracts and
 * ensures that only valid child contracts can be registered.
 */
contract QWRegistry is IQWRegistry {
  // Variables
  address public immutable QW_MANAGER;
  mapping(address => bool) public whitelist;

  // Events
  event ChildRegistered(address indexed child);

  // Custom errors
  error ParentMismatch(); // Error for mismatched parent contract
  error InvalidAddress(); // Error for invalid address

  // Constructor
  /**
   * @dev Initializes the QWRegistry contract with the address of the Quant Wealth Manager contract.
   * @param _qwManager The address of the Quant Wealth Manager contract.
   */
  constructor(address _qwManager) {
    QW_MANAGER = _qwManager;
  }

  // External Functions

  /**
   * @notice Registers a child contract in the whitelist.
   * @dev This function ensures that the child contract's parent matches the QWManager.
   * @param _child The address of the child contract to register.
   */
  function registerChild(address _child) external {
    if (_child == address(0)) {
      revert InvalidAddress();
    }
    IQWChild childContract = IQWChild(_child);
    if (childContract.QW_MANAGER() != QW_MANAGER) {
      revert ParentMismatch();
    }
    whitelist[_child] = true;
    emit ChildRegistered(_child); // Emit an event when a child contract is registered
  }
}
