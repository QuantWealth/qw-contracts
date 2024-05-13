// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Quant Wealth Manager Contract
 * @author quantwealth
 * @notice TODO: Add a description
 */
interface IQWManager {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/
  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /*///////////////////////////////////////////////////////////////
                            FUNCTIONS
  //////////////////////////////////////////////////////////////*/
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
    uint256[] _amount
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
   * @param _targetQwi ...
   * @param _callData ...
   */
  function withdraw(address user, uint256 amount) external;
}
