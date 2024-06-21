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
   * @param _tokenAmount Amount of tokens to be transferred to the child contract.
   * @return success boolean indicating whether the transaction was successful.
   * @return shares Number of shares to be allocated to the user in return for investment created.
   */
  function create(
    bytes memory _callData,
    uint256 _tokenAmount
  ) external returns (bool success, uint256 shares);

  /**
   * @notice Closes a transaction on the child contract.
   * @dev This function is called by the parent contract to close a transaction on the child contract.
   * @param _callData Encoded function call to be executed on the child contract.
   * @param _sharesAmount Amount of shares to be withdrawn, will determine tokens withdrawn.
   * @return success boolean indicating whether the transaction was successfully closed.
   * @return tokens Number of tokens to be returned to the user in exchange for shares withdrawn.
   */
  function close(
    bytes memory _callData,
    uint256 _sharesAmount
  ) external returns (bool success, uint256 tokens);

  /**
   * @notice Gets the address of the Quant Wealth Manager contract.
   * @return address The address of the Quant Wealth Manager contract recorded in this child contract.
   */
  function QW_MANAGER() external view returns (address);

  /**
   * @notice Gets the address of the target investment token.
   * @dev Returns the address of the token that is initially invested and received on withdraw.
   * @return address The address of the investment token.
   */
  function INVESTMENT_TOKEN() external view returns (address);
}
