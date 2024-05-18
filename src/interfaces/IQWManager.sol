// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

/**
 * @title Quant Wealth Manager Contract Interface
 * @notice This interface defines the functions to manage various strategies for Quant Wealth.
 */
interface IQWManager {
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
  ) external;

  /**
   * @notice Close a series of investments.
   * Calls target contracts with provided calldata to close positions.
   * @param _targetQwChild List of contract addresses to interact with.
   * @param _callData Encoded function calls to be executed on the target contracts.
   */
  function close(address[] memory _targetQwChild, bytes[] memory _callData) external;

  /**
   * @notice Withdraw funds to a specified user.
   * Transfers a specified amount of funds to the user.
   * @param _user The address of the user to receive the funds.
   * @param _amount The amount of funds to transfer to the user.
   */
  function withdraw(address _user, uint256 _amount) external;

  /**
   * @notice Get the address of the Quant Wealth Registry.
   */
  function REGISTRY() external view returns (address);
}
