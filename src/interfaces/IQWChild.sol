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

  /**
   * @notice Gets the address of the Quant Wealth Manager contract.
   * @return address The address of the Quant Wealth Manager contract recorded in this child contract.
   */
  function getQWManager() external view returns (address);

  /**
   * @notice Gets the address of the investment token, the token input and output for the contract.
   * @return address The address of the investment token.
   */
  function getInvestmentToken() external view returns (address);

  /**
   * @notice Gets the address of the asset token, the token that is purchased and sold using the investment token.
   * @return address The address of the asset token.
   */
  function getAssetToken() external view returns (address);
}
