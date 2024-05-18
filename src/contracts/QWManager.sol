// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {QWRegistry} from './QWRegistry.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IQWChild} from 'interfaces/IQWChild.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';

/**
 * @title Quant Wealth Manager Contract
 * @notice This contract manages the execution, closing, and withdrawal of various strategies for Quant Wealth.
 */
contract QWManager is IQWManager {
  // Variables
  address public immutable REGISTRY;

  // Custom errors
  error InvalidInputLength(); // Error for mismatched input lengths
  error ContractNotWhitelisted(); // Error for contract not whitelisted
  error CallFailed(); // Error for call failed

  // Constructor
  constructor() {
    QWRegistry _registry = new QWRegistry(address(this));
    REGISTRY = address(_registry);
  }

  // External Functions
  /**
   * @notice Execute a series of investments.
   * Transfers specified amounts of tokens and calls target contracts with provided calldata.
   * @param _targetQwChild List of contract addresses to interact with.
   * @param _callData Encoded function calls to be executed on the target contracts.
   * @param _tokenAddress Token address to transfer.
   * @param _amount Amount of tokens to transfer to each target contract.
   */
  function execute(
    address[] memory _targetQwChild,
    bytes[] memory _callData,
    address _tokenAddress,
    uint256 _amount
  ) external {
    if (_targetQwChild.length != _callData.length) {
      revert InvalidInputLength();
    }

    for (uint256 i = 0; i < _targetQwChild.length; i++) {
      if (!IQWRegistry(REGISTRY).whitelist(_targetQwChild[i])) {
        revert ContractNotWhitelisted();
      }

      IERC20 token = IERC20(_tokenAddress);
      token.approve(address(_targetQwChild[i]), _amount);

      (bool success) = IQWChild(_targetQwChild[i]).create(_callData[i], _tokenAddress, _amount);
      if (!success) {
        revert CallFailed();
      }
    }
  }

  /**
   * @notice Close a series of investments.
   * Calls target contracts with provided calldata to close positions.
   * @param _targetQwChild List of contract addresses to interact with.
   * @param _callData Encoded function calls to be executed on the target contracts.
   */
  function close(address[] memory _targetQwChild, bytes[] memory _callData) external {
    if (_targetQwChild.length != _callData.length) {
      revert InvalidInputLength();
    }

    for (uint256 i = 0; i < _targetQwChild.length; i++) {
      (, address lpAsset, uint256 amount) = abi.decode(_callData[i], (address, address, uint256));
      IERC20 token = IERC20(lpAsset);
      token.approve(address(_targetQwChild[i]), amount);

      (bool success) = IQWChild(_targetQwChild[i]).close(_callData[i]);
      if (!success) {
        revert CallFailed();
      }
    }
  }

  /**
   * @notice Withdraw funds to a specified user.
   * Transfers a specified amount of funds to the user.
   * @param user The address of the user to receive the funds.
   * @param amount The amount of funds to transfer to the user.
   */
  function withdraw(address user, uint256 amount) external {
    payable(user).transfer(amount);
  }
}
