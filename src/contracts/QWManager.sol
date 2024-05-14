// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {QWRegistry} from './QWRegistry.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';

/**
 * @title Quant Wealth Manager Contract
 * @notice This contract manages the execution, closing, and withdrawal of various strategies for Quant Wealth.
 * It inherits access control functionality from QWWing and QWGuardian for role-based access.
 */
contract QWManager is IQWManager {
  /// Errors
  error QWManager__onlyAdmin_notAdmin();

  /// Storage
  address public immutable registry;

  /// Constructor
  /**
   * @dev Constructor that sets up the default admin role and initializes the QWWing and QWGuardian contracts with the operator address.
   */
  constructor() {
    QWRegistry _registry = new QWRegistry(address(this));
    registry = address(_registry);
  }

  /// External Functions
  /**
   * @notice Execute a series of transactions.
   * @dev This function can only be called by an address with the WING_OPERATOR_ROLE.
   * Transfers specified amounts of tokens and calls target contracts with provided calldata.
   * @param _targetQwChild List of contract addresses to interact with.
   * @param _callData Encoded function calls to be executed on the target contracts.
   * @param _tokenAddress List of token addresses to transfer.
   * @param _amount List of amounts corresponding to each token to be transferred.
   */
  function execute(
    address[] memory _targetQwChild,
    bytes[] memory _callData,
    address _tokenAddress,
    uint256 _amount
  ) external override {
    require(_targetQwChild.length == _callData.length, 'QWManager: Mismatched input lengths');

    for (uint256 i = 0; i < _targetQwChild.length; i++) {
      IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
      (bool success,) = _targetQwChild[i].call(_callData[i]);
      require(success, 'QWManager: Call failed');
    }
  }

  /**
   * @notice Close a series of transactions.
   * @dev This function can only be called by an address with the GUARDIAN_OPERATOR_ROLE.
   * Calls target contracts with provided calldata to close positions.
   * @param _targetQwChild List of contract addresses to interact with.
   * @param _callData Encoded function calls to be executed on the target contracts.
   */
  function close(address[] memory _targetQwChild, bytes[] memory _callData) external override {
    require(_targetQwChild.length == _callData.length, 'QWManager: Mismatched input lengths');

    for (uint256 i = 0; i < _targetQwChild.length; i++) {
      (bool success,) = _targetQwChild[i].call(_callData[i]);
      require(success, 'QWManager: Call failed');
    }
  }

  /**
   * @notice Withdraw funds to a specified user.
   * @dev This function can only be called by an address with the GUARDIAN_OPERATOR_ROLE.
   * Transfers a specified amount of funds to the user.
   * @param user The address of the user to receive the funds.
   * @param amount The amount of funds to transfer to the user.
   */
  function withdraw(address user, uint256 amount) external override {
    payable(user).transfer(amount);
  }
}
