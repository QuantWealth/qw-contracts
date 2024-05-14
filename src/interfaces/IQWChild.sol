// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Interface for Quant Wealth Integration Child Contract
 * @author Quant Wealth
 * @notice ...
 */
interface IQWChild {


  /// functions
  function withdraw() external view returns (address);

  /**
   * @notice ...
   * @dev ...
   * @param _callData ...
   * @param _tokenAddress ...
   * @param _amount ...
   */
  function create(
    bytes memory _callData,
    address  _tokenAddress,
    uint256  _amount
  ) external;

  /**
   * @notice ...
   * @dev ...
   * @param _callData ...
   */
  function close(
    bytes memory _callData
  ) external;
}