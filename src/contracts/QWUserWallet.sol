// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/**
 * @title Quant Wealth User Wallet Contract
 * @notice This contract allows users to deposit tokens and transfer them to specified dapps with ECDSA signature verification.
 */
contract QWUserWallet {
    using ECDSA for bytes32;

    /// Struct to manage transfer details
    struct Transfer {
        address dapp;
        uint256 amount;
        address token;
    }

    /// Mapping to track user deposits
    mapping(address => mapping(address => uint256)) public balances;

    /// Events
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event TransferExecuted(address indexed user, address indexed dapp, address indexed token, uint256 amount);

    /**
     * @notice Deposit tokens into the user wallet.
     * @param token The address of the token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address token, uint256 amount) external {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "QWUserWallet: Transfer failed");
        balances[msg.sender][token] += amount;
        emit Deposit(msg.sender, token, amount);
    }

    /**
     * @notice Transfer tokens to specified dapps.
     * @dev Requires a valid ECDSA signature from the user.
     * @param transfers An array of Transfer structs containing dapp addresses, amounts, and tokens.
     * @param signature The ECDSA signature to verify the user's approval.
     */
    function transfer(Transfer[] calldata transfers, bytes calldata signature) external {
        bytes32 hash = keccak256(abi.encode(transfers));
        address signer = hash.toEthSignedMessageHash().recover(signature);
        require(signer == msg.sender, "QWUserWallet: Invalid signature");

        for (uint256 i = 0; i < transfers.length; i++) {
            Transfer memory transferDetails = transfers[i];
            require(balances[msg.sender][transferDetails.token] >= transferDetails.amount, "QWUserWallet: Insufficient balance");

            balances[msg.sender][transferDetails.token] -= transferDetails.amount;
            require(IERC20(transferDetails.token).transfer(transferDetails.dapp, transferDetails.amount), "QWUserWallet: Transfer failed");

            emit TransferExecuted(msg.sender, transferDetails.dapp, transferDetails.token, transferDetails.amount);
        }
    }
}
