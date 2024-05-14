// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Quant Wealth Manager Contract
 * @author quantwealth
 * @notice TODO: Add a description
 */
interface IQWManager {

  /// functions
  /**
   * @notice ...
   * @dev Only callable by the wing
   * @param _targetQwi ...
   * @param _callData ...
   * @param _tokenAddress ...
   * @param _amount ...
   */
  function execute(
    address[] memory _targetQwi,
    bytes[] memory _callData,
    address[] memory _tokenAddress,
    uint256[] memory _amount
  ) external;

  /**
   * @notice ...
   * @dev Only callable by the wing
   * @param _targetQwi ...
   * @param _callData ...
   */
  function close(address[] memory _targetQwi, bytes[] memory _callData) external;

  /**
   * @notice ...
   * @dev Only callable by the wing
   * @param _user ...
   * @param _amount ...
   */
  function withdraw(address _user, uint256 _amount) external;
}
