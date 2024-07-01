// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

/**
 * @title Quant Wealth Manager Contract Interface
 * @notice This interface defines the functions to manage various strategies for Quant Wealth.
 */
interface IQWManager {
  /**
   * @notice Execute a series of investments in batches for multiple protocols.
   * Transfers specified amounts of tokens and calls target contracts with provided calldata.
   * @param batches Array of OpenBatch data containing protocol and amount.
   */
  function open(OpenBatch[] memory batches) external;

  /**
   * @notice Close a series of investments in batches for multiple protocols.
   * Calls target contracts with provided calldata to close positions.
   * @param batches Array of CloseBatch data containing protocol and ratio.
   */
  function close(CloseBatch[] memory batches) external;

  /**
   * @notice Withdraw funds to a specified user.
   * Transfers a specified amount of funds to the user.
   * @param _user The address of the user to receive the funds.
   * @param _tokenAddress The address of the token to transfer.
   * @param _amount The amount of funds to transfer to the user.
   */
  function withdraw(address _user, address _tokenAddress, uint256 _amount) external;

  /**
   * @notice Receive funds from a specified user.
   * Transfers a specified amount of funds from the user to this contract.
   * @param _user The address of the user sending the funds.
   * @param _tokenAddress The address of the token to transfer.
   * @param _amount The amount of funds to transfer to this contract.
   */
  function receiveFunds(address _user, address _tokenAddress, uint256 _amount) external;

  /**
   * @notice Get the address of the Quant Wealth Registry.
   * @return The address of the registry contract.
   */
  function REGISTRY() external view returns (address);

  /**
   * @notice OpenBatch struct to hold batch data for executing investments.
   * @param protocol The protocol into which we are investing funds.
   * @param amount The total amount being invested in the given token by all users into this protocol.
   */
  struct OpenBatch {
      address protocol;
      uint256 amount;
  }

  /**
   * @notice CloseBatch struct to hold batch data for closing investments.
   * @param protocol The protocol from which we are withdrawing funds.
   * @param ratio The percentage amount of holdings to withdraw from the given protocol.
   */
  struct CloseBatch {
      address protocol;
      uint256 ratio;
  }
}
