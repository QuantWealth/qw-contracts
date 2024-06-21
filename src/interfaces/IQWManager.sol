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
   * @param batches Array of ExecuteBatch data containing protocol, users, contributions, token, and amount.
   */
  function execute(ExecuteBatch[] memory batches) external;

  /**
   * @notice Close a series of investments in batches for multiple protocols.
   * Calls target contracts with provided calldata to close positions.
   * @param batches Array of CloseBatch data containing protocol, users, contributions, token, and shares.
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
   * @notice ExecuteBatch struct to hold batch data for executing investments.
   * @param protocol The protocol into which we are investing funds.
   * @param users The users investing.
   * @param contributions Contribution fractions in basis points (e.g., 1% = 100, 100% = 10000).
   * @param amount The total amount being invested in the given token by all users into this protocol.
   */
  struct ExecuteBatch {
      address protocol;
      address[] users;
      uint256[] contributions;
      uint256 amount;
  }

  /**
   * @notice CloseBatch struct to hold batch data for closing investments.
   * @param protocol The protocol from which we are withdrawing funds.
   * @param users The users withdrawing.
   * @param contributions Contribution fractions in basis points (e.g., 1% = 100, 100% = 10000).
   * @param shares The total shares being withdrawn from the given protocol by all users.
   */
  struct CloseBatch {
      address protocol;
      address[] users;
      uint256[] contributions;
      uint256 shares;
  }
}
