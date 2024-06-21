// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {QWRegistry} from './QWRegistry.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWChild} from 'interfaces/IQWChild.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';

/**
 * @title Quant Wealth Manager Contract
 * @notice This contract manages the execution, closing, and withdrawal of various strategies for Quant Wealth.
 */
contract QWManager is IQWManager, Ownable {
    // Variables
    address public immutable REGISTRY;

    // Mapping to store user shares for each protocol
    mapping(address => mapping(address => uint256)) public shares;
    // Mapping to store total shares for each protocol
    mapping(address => uint256) public totalShares;

    // Custom errors
    error InvalidInputLength(); // Error for mismatched input lengths
    error ContractNotWhitelisted(); // Error for contract not whitelisted
    error CallFailed(); // Error for call failed

    // Constructor
    constructor() Ownable(msg.sender) {
        // Deploy the QWRegistry contract and set the REGISTRY address
        QWRegistry _registry = new QWRegistry(address(this), msg.sender);
        REGISTRY = address(_registry);
    }

    // External Functions

    /**
     * @notice Execute a series of investments in batches for multiple protocols.
     * Transfers specified amounts of tokens and calls target contracts with provided calldata.
     * @param batches Array of ExecuteBatch data containing protocol, users, contributions, token, and amount.
     */
    function execute(ExecuteBatch[] memory batches) external onlyOwner {
        for (uint256 i = 0; i < batches.length; i++) {
            ExecuteBatch memory batch = batches[i];

            // Check if the target contract is whitelisted
            if (!IQWRegistry(REGISTRY).whitelist(batch.protocol)) {
                revert ContractNotWhitelisted();
            }

            // Approve the target contract to spend the specified amount of tokens
            IERC20 token = IERC20(batch.token);
            token.approve(address(batch.protocol), batch.amount);

            // Encode necessary data for child contract
            bytes memory encodedData = abi.encode(totalShares[batch.protocol]);

            // Call the create function on the target contract with the provided calldata
            (bool success, bytes memory result) = IQWChild(batch.protocol).create(encodedData, batch.amount);
            if (!success) {
                revert CallFailed();
            }

            // Decode shares from result
            (uint256 totalSharesReceived) = abi.decode(result, (uint256));

            // Distribute the shares to users
            for (uint256 j = 0; j < batch.users.length; j++) {
                uint256 userShare = (totalSharesReceived * batch.contributions[j]) / 10000;
                _updateSharesOnDeposit(batch.users[j], userShare, totalShares[batch.protocol], batch.protocol);
            }
        }
    }

    /**
     * @notice Close a series of investments in batches for multiple protocols.
     * Calls target contracts with provided calldata to close positions.
     * @param batches Array of CloseBatch data containing protocol, users, contributions, token, and shares.
     */
    function close(CloseBatch[] memory batches) external onlyOwner {
        for (uint256 i = 0; i < batches.length; i++) {
            CloseBatch memory batch = batches[i];

            // Encode necessary data for child contract
            bytes memory encodedData = abi.encode(totalShares[batch.protocol]);

            // Call the close function on the target contract with the provided calldata
            (bool success, bytes memory result) = IQWChild(batch.protocol).close(
                encodedData,
                batch.shares
            );
            if (!success) {
                revert CallFailed();
            }

            // Decode tokens received from result
            (uint256 tokens) = abi.decode(result, (uint256));

            // Distribute the tokens to users
            for (uint256 j = 0; j < batch.users.length; j++) {
                // TODO: Handle potential leftover value due to division rounding
                _updateSharesOnWithdrawal(batch.users[j], batch.contributions[j], batch.protocol);
                uint256 userShares = (batch.shares * batch.contributions[j]) / 10000;
                // TODO: transfer userTokens to user
                // uint256 userTokens = (tokens * batch.contributions[j]) / 10000;
            }
        }
    }

    /**
     * @notice Withdraw funds to a specified user.
     * Transfers a specified amount of funds to the user.
     * @param _user The address of the user to receive the funds.
     * @param _tokenAddress The address of the token to transfer.
     * @param _amount The amount of funds to transfer to the user.
     */
    function withdraw(address _user, address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(_user, _amount);
    }

    /**
     * @notice Receive funds from a specified user.
     * Transfers a specified amount of funds from the user to this contract.
     * @param _user The address of the user sending the funds.
     * @param _tokenAddress The address of the token to transfer.
     * @param _amount The amount of funds to transfer to this contract.
     */
    function receiveFunds(address _user, address _tokenAddress, uint256 _amount) external {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(_user, address(this), _amount);
    }

    // Internal Functions

    /**
     * @notice Internal function to update shares on deposit.
     * @param user The address of the user whose shares are being updated.
     * @param sharesAmount The amount of shares to add to the user's balance.
     * @param totalSharesProtocol The total shares in the protocol before the deposit.
     * @param protocol The address of the protocol.
     */
    function _updateSharesOnDeposit(address user, uint256 sharesAmount, uint256 totalSharesProtocol, address protocol) internal {
        shares[protocol][user] += sharesAmount;
        totalShares[protocol] = totalSharesProtocol + sharesAmount;
    }

    /**
     * @notice Internal function to update shares on withdrawal.
     * @param user The address of the user whose shares are being updated.
     * @param userShares The amount of shares to subtract from the user's balance.
     * @param protocol The address of the protocol.
     */
    function _updateSharesOnWithdrawal(address user, uint256 userShares, address protocol) internal {
        shares[protocol][user] -= userShares;
        totalShares[protocol] -= userShares;
    }
}
