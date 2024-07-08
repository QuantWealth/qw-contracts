// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';

/**
 * @title Quant Wealth Registry Contract
 * @notice This contract manages the registration of child contracts and
 * ensures that only valid child contracts can be registered.
 */
contract QWRegistry is IQWRegistry, Ownable {
  // Variables
  address public immutable QW_MANAGER;
  mapping(address => bool) public whitelist;

  // Events
  event ComponentRegistered(address indexed component);

  // Custom errors
  error ParentMismatch(); // Error for mismatched parent contract
  error InvalidAddress(); // Error for invalid address

  // Constructor
  /**
   * @dev Initializes the QWRegistry contract with the address of the Quant Wealth Manager contract.
   * @param _qwManager The address of the Quant Wealth Manager contract.
   */
  constructor(address _qwManager, address _owner) Ownable(_owner) {
    QW_MANAGER = _qwManager;
  }

  // External Functions

  /**
   * @notice Registers a child contract in the whitelist.
   * @dev This function ensures that the component contract's parent matches the QWManager.
   * @param _component The address of the component contract to register.
   */
  function registerComponent(address _component) external onlyOwner {
    if (_component == address(0)) {
      revert InvalidAddress();
    }
    IQWComponent componentContract = IQWComponent(_component);
    if (componentContract.getQWManager() != QW_MANAGER) {
      revert ParentMismatch();
    }
    whitelist[_component] = true;
    emit ComponentRegistered(_component); // Emit an event when a child contract is registered
  }
}
