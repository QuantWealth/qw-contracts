// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

/**
 * @title Quant Wealth Manager Contract Interface
 * @notice This interface defines the functions to manage various strategies for Quant Wealth.
 */
interface IQWManager {
    /**
     * @notice OpenBatch struct to hold batch data for executing investments.
     * @param component The component into which we are investing funds.
     * @param token The token being invested.
     * @param amount The total amount being invested in the given token by all users into this component.
     * @param asset The address of the asset for which the investment is made.
     */
    struct OpenBatch {
        address component;
        address token;
        uint256 amount;
        address asset;
    }

    /**
     * @notice CloseBatch struct to hold batch data for closing investments.
     * @param component The component from which we are withdrawing funds.
     * @param ratio The percentage amount of holdings to withdraw from the given component.
     * @param asset The address of the asset being withdrawn.
     */
    struct CloseBatch {
        address component;
        uint256 ratio;
        address asset;
    }

    /**
     * @notice Execute a series of investments in batches for multiple protocols.
     * Transfers specified amounts of tokens and calls target contracts with provided calldata.
     * @param batches Array of OpenBatch data containing component, amount, and asset.
     */
    function open(OpenBatch[] memory batches) external;

    /**
     * @notice Close a series of investments in batches for multiple protocols.
     * Calls target contracts with provided calldata to close positions.
     * @param batches Array of CloseBatch data containing component, ratio, and asset.
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
}
