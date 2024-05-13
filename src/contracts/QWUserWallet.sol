// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/**
 * @title Quant Wealth User Wallet Contract
 * @notice This contract allows users to deposit tokens and transfer them to enact a specified strategy composed of
 * selected dapps in the ecosystem using ECDSA signature verification to perform meta transactions. Implements 
 * EIP3074 and EIP4337.
 */
contract QWUserWallet {
    using ECDSA for bytes32;

    /// Errors
    error QWUserWallet__InvalidSignature();
    error QWUserWallet__InsufficientBalance(address token, uint256 available, uint256 required);
    error QWUserWallet__TransferFailed(address token, address to, uint256 amount);

    /// Struct to manage transfer details.
    struct Transfer {
        address dapp;
        uint256 amount;
        address token;
    }

    /// Storage
    // Mapping to track user deposits.
    mapping(address => mapping(address => uint256)) public userBalances;

    /// Events
    event DepositExecuted(address indexed user, address indexed token, uint256 amount);
    event TransferExecuted(address indexed user, address indexed dapp, address indexed token, uint256 amount);

    /// Functions
    /**
     * @notice Deposit tokens into the user wallet.
     * @param token The address of the token to deposit.
     * @param amount The amount of tokens to deposit.
     * @param signature The ECDSA signature to verify the user's approval.
     */
    function deposit(address token, uint256 amount, bytes calldata signature) external {
        _verifySignature(msg.sender, keccak256(abi.encode(token, amount)), signature);
        _deposit(msg.sender, token, amount);
    }

    /**
     * @notice Transfer tokens to specified dapps.
     * @param transfers An array of Transfer structs containing dapp addresses, amounts, and tokens.
     * @param signature The ECDSA signature to verify the user's approval.
     */
    function transfer(Transfer[] calldata transfers, bytes calldata signature) external {
        _verifySignature(msg.sender, keccak256(abi.encode(transfers)), signature);
        _transfer(msg.sender, transfers);
    }

    /**
     * @dev Private function to verify the ECDSA signature.
     * @param user The address of the user.
     * @param hash The hash of the data to be signed.
     * @param signature The ECDSA signature to verify.
     */
    function _verifySignature(address user, bytes32 hash, bytes calldata signature) private view {
        address signer = hash.toEthSignedMessageHash().recover(signature);
        if (signer != user) revert QWUserWallet__InvalidSignature();
    }

    /**
     * @dev Private function to handle deposits.
     * @param user The address of the user.
     * @param token The address of the token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function _deposit(address user, address token, uint256 amount) private {
        if (!IERC20(token).transferFrom(user, address(this), amount)) {
            revert QWUserWallet__TransferFailed(token, address(this), amount);
        }
        userBalances[user][token] += amount;
        emit DepositExecuted(user, token, amount);
    }

    /**
     * @dev Private function to handle transfers.
     * @param user The address of the user.
     * @param transfers An array of Transfer structs containing dapp addresses, amounts, and tokens.
     */
    function _transfer(address user, Transfer[] calldata transfers) private {
        for (uint256 i = 0; i < transfers.length; i++) {
            Transfer memory transferDetails = transfers[i];
            if (userBalances[user][transferDetails.token] < transferDetails.amount) {
                revert QWUserWallet__InsufficientBalance(transferDetails.token, userBalances[user][transferDetails.token], transferDetails.amount);
            }

            userBalances[user][transferDetails.token] -= transferDetails.amount;
            if (!IERC20(transferDetails.token).transfer(transferDetails.dapp, transferDetails.amount)) {
                revert QWUserWallet__TransferFailed(transferDetails.token, transferDetails.dapp, transferDetails.amount);
            }

            emit TransferExecuted(user, transferDetails.dapp, transferDetails.token, transferDetails.amount);
        }
    }
}
