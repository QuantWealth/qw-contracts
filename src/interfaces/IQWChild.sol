// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

/**
 * @title Interface for Quant Wealth Integration Child Contract
 * @notice This interface defines the functions for interacting with the Quant Wealth Integration Child contract.
 */
interface IQWChild {
  /**
   * @notice Executes a transaction on the child contract.
   * @dev This function is called by the parent contract to execute a transaction on the child contract.
   * @param _callData Encoded function call to be executed on the child contract.
   * @param _tokenAddress Address of the token to be transferred.
   * @param _amount Amount of tokens to be transferred to the child contract.
   * @return success boolean indicating whether the transaction was successful.
   */
  function create(bytes memory _callData, address _tokenAddress, uint256 _amount) external returns (bool success);

  /**
   * @notice Closes a transaction on the child contract.
   * @dev This function is called by the parent contract to close a transaction on the child contract.
   * @param _callData Encoded function call to be executed on the child contract.
   * @return success boolean indicating whether the transaction was successfully closed.
   */
  function close(bytes memory _callData) external returns (bool success);

  /**
   * @notice Gets the address of the Quant Wealth Manager contract.
   * @dev Returns the address of the Quant Wealth Manager contract.
   */
  function QW_MANAGER() external view returns (address);
}
