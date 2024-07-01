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
   * @param _amount Amount of tokens to be transferred to the child contract.
   * @return success boolean indicating whether the transaction was successful.
   * @return assetAmountReceived The total amount of asset tokens received in return for the investment.
   */
  function open(
    uint256 _amount
  ) external returns (bool success, uint256 assetAmountReceived);

  /**
   * @notice Closes a transaction on the child contract.
   * @dev This function is called by the parent contract to close a transaction on the child contract.
   * @param _amount Amount of holdings to be withdrawn.
   * @return success boolean indicating whether the transaction was successfully closed.
   * @return tokenAmountReceived Number of tokens to be returned to the user in exchange for the withdrawn ratio.
   */
  function close(
    uint256 _amount
  ) external returns (bool success, uint256 tokenAmountReceived);
}
