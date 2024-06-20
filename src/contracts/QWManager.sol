// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {QWRegistry} from './QWRegistry.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWChild} from 'interfaces/IQWChild.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';
import {QWShares} from './QWShares.sol';

/**
 * @title Quant Wealth Manager Contract
 * @notice This contract manages the execution, closing, and withdrawal of various strategies for Quant Wealth.
 */
contract QWManager is IQWManager, Ownable, QWShares {
    // Variables
    address public immutable REGISTRY;

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
     * @notice Execute a series of investments.
     * Transfers specified amounts of tokens and calls target contracts with provided calldata.
     * @param _targetQwChild List of contract addresses to interact with.
     * @param _callData Encoded function calls to be executed on the target contracts.
     * @param _tokenAddress Token address to transfer.
     * @param _amount Amount of tokens to transfer to each target contract.
     */
    function execute(
        address[] memory _targetQwChild,
        bytes[] memory _callData,
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        if (_targetQwChild.length != _callData.length) {
            revert InvalidInputLength();
        }

        for (uint256 i = 0; i < _targetQwChild.length; i++) {
            // Check if the target contract is whitelisted
            if (!IQWRegistry(REGISTRY).whitelist(_targetQwChild[i])) {
                revert ContractNotWhitelisted();
            }

            // Approve the target contract to spend the specified amount of tokens
            IERC20 token = IERC20(_tokenAddress);
            token.approve(address(_targetQwChild[i]), _amount);

            // Encode necessary data for child contract
            bytes memory encodedData = abi.encode(totalShares[_targetQwChild[i]]);

            // Call the create function on the target contract with the provided calldata
            (bool success, bytes memory result) = IQWChild(_targetQwChild[i]).create(encodedData, _tokenAddress, _amount);
            if (!success) {
                revert CallFailed();
            }

            // Decode shares from result
            (uint256 shares) = abi.decode(result, (uint256));

            // Update shares in QWManager
            _updateSharesOnDeposit(msg.sender, shares, _targetQwChild[i]);
        }
    }

    /**
     * @notice Close a series of investments.
     * Calls target contracts with provided calldata to close positions.
     * @param _targetQwChild List of contract addresses to interact with.
     * @param _callData Encoded function calls to be executed on the target contracts.
     */
    function close(address[] memory _targetQwChild, bytes[] memory _callData) external onlyOwner {
        if (_targetQwChild.length != _callData.length) {
            revert InvalidInputLength();
        }

        for (uint256 i = 0; i < _targetQwChild.length; i++) {
            // Decode the calldata to get the LP asset address and amount
            (address _user, uint256 _sharesAmount) = abi.decode(_callData[i], (address, uint256));

            // Encode necessary data for child contract
            bytes memory encodedData = abi.encode(_user, _sharesAmount, totalShares[_targetQwChild[i]], _targetQwChild[i]);

            // Call the close function on the target contract with the provided calldata
            (bool success) = IQWChild(_targetQwChild[i]).close(encodedData);
            if (!success) {
                revert CallFailed();
            }

            // Update shares in QWManager
            _updateSharesOnWithdrawal(_user, _sharesAmount, _targetQwChild[i]);
        }
    }

    /**
     * @notice Withdraw funds to a specified user.
     * Transfers a specified amount of funds to the user.
     * @param user The address of the user to receive the funds.
     * @param _tokenAddress The address of the token to transfer.
     * @param _amount The amount of funds to transfer to the user.
     */
    function withdraw(address user, address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(user, _amount);
    }

    /**
     * @notice Receive funds from a specified user.
     * Transfers a specified amount of funds from the user to this contract.
     * @param user The address of the user sending the funds.
     * @param _tokenAddress The address of the token to transfer.
     * @param _amount The amount of funds to transfer to this contract.
     */
    function receiveFunds(address user, address _tokenAddress, uint256 _amount) external {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(user, address(this), _amount);
    }
}
