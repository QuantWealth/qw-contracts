// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

/**
 * @title Interface for Quant Wealth Registry Contract
 * @notice This interface defines the functions for interacting with the Quant Wealth Registry contract.
 */
interface IQWRegistry {
  /**
   * @notice Registers a component contract in the whitelist.
   * @dev Adds the specified component contract to the whitelist.
   * @param _component The address of the component contract to register.
   */
  function registerComponent(address _component) external;

  /**
   * @notice Checks if a component contract is whitelisted.
   * @dev Returns true if the specified component contract is whitelisted, otherwise false.
   * @param _component The address of the component contract to check.
   * @return boolean A boolean indicating whether the component contract is whitelisted.
   */
  function whitelist(address _component) external view returns (bool);

  /**
   * @notice Gets the address of the Quant Wealth Manager contract.
   * @dev Returns the address of the Quant Wealth Manager contract.
   */
  function QW_MANAGER() external view returns (address);
}
