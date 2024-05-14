// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Quant Wealth Manager Contract
 * @notice This interface defines the functions to manage various strategies for Quant Wealth.
 */
interface IQWManager {
  /**
   * @notice Execute a series of investments.
   * @dev This function transfers specified amounts of tokens and calls target contracts with provided calldata.
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
  ) external;

  /**
   * @notice Close a series of investments.
   * @dev This function calls target contracts with provided calldata to close positions.
   * @param _targetQwChild List of contract addresses to interact with.
   * @param _callData Encoded function calls to be executed on the target contracts.
   */
  function close(address[] memory _targetQwChild, bytes[] memory _callData) external;

  /**
   * @notice Withdraw funds to a specified user.
   * @dev This function transfers a specified amount of funds to the user.
   * @param _user The address of the user to receive the funds.
   * @param _amount The amount of funds to transfer to the user.
   */
  function withdraw(address _user, uint256 _amount) external;
}
