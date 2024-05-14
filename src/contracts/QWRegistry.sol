// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IQWChild} from 'interfaces/IQWChild.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';

/**
 * @title Interface for Quant Wealth Registry Contract
 * @author Quant Wealth
 * @notice ...
 */
contract QWRegistry is IQWRegistry {
  /// Variables
  address public immutable qwManager;

  mapping(address => bool) public whitelist;

  /// Constructor
  /**
   * @dev ...
   */
  constructor(address _qwManager) {
    qwManager = _qwManager;
  }

  /**
   * @notice ...
   * @dev ...
   * @param _child ...
   */
  function registerChild(address _child) external {
    require(IQWChild(_child).qwManager.address == qwManager, 'qwManager should be the same as the parent contract');
    whitelist[_child] = true;
  }
}
