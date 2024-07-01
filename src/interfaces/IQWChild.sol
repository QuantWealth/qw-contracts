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
  function create(
    uint256 _amount
  ) external returns (bool success, uint256 assetAmountReceived);

  /**
   * @notice Closes a transaction on the child contract.
   * @dev This function is called by the parent contract to close a transaction on the child contract.
   * @param _ratio Percentage of holdings to be withdrawn, with 8 decimal places for precision.
   * @return success boolean indicating whether the transaction was successfully closed.
   * @return tokenAmountReceived Number of tokens to be returned to the user in exchange for the withdrawn ratio.
   */
  function close(
    uint256 _ratio
  ) external returns (bool success, uint256 tokenAmountReceived);

  /**
   * @notice Gets the total amount of the asset currently held.
   * @return uint256 The total amount of the asset currently held.
   */
  function holdings() external view returns (uint256);

  /**
   * @notice Calculates the amount of tokens to be withdrawn for a given ratio.
   * @param _ratio Percentage of holdings for which to calculate a withdraw, with 8 decimal places for precision.
   * @return uint256 The amount of tokens that would be received for the given ratio.
   */
  function calc(uint256 _ratio) external view returns (uint256);

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
