// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IPool} from '@aave/core-v3/contracts/interfaces/IPool.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';
import {QWComponentBase} from './QWComponentBase.sol';

/**
 * @title AaveV3 Integration for Quant Wealth
 * @notice This contract integrates with AaveV3 protocol for Quant Wealth management.
 */
contract QWAaveV3 is IQWComponent, QWComponentBase {
    // Variables
    address public immutable POOL;

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param _qwManager The address of the Quant Wealth Manager contract.
     * @param _investmentToken The address of the token to be invested.
     * @param _assetToken The address of the asset token received after investment.
     * @param _pool The address of the AaveV3 pool contract.
     */
    constructor(
        address _qwManager,
        address _investmentToken,
        address _assetToken,
        address _pool
    ) QWComponentBase(_qwManager, _investmentToken, _assetToken) {
        POOL = _pool;
    }

    // Functions
    /**
     * @notice Executes a transaction on AaveV3 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV3 pool.
     * @param _amount Amount of tokens to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived Amount of assets received from the deposit.
     */
    function open(uint256 _amount) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        IERC20 token = IERC20(INVESTMENT_TOKEN);
        token.transferFrom(QW_MANAGER, address(this), _amount);
        token.approve(POOL, _amount);

        IPool(POOL).supply(INVESTMENT_TOKEN, _amount, address(this), 0);
        assetAmountReceived = IERC20(ASSET_TOKEN).balanceOf(address(this));

        // TODO: Transfer tokens to QWManager

        success = true;
    }

    /**
     * @notice Executes a transaction on AaveV3 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV3 pool.
     * @param _ratio Percentage of holdings to be withdrawn, with 8 decimal places for precision.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived Amount of tokens received from the withdrawal.
     */
    function close(uint256 _ratio) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        uint256 totalHoldings = IERC20(ASSET_TOKEN).balanceOf(address(this));
        uint256 amountToWithdraw = (totalHoldings * _ratio) / 1e8;

        IPool(POOL).withdraw(INVESTMENT_TOKEN, amountToWithdraw, QW_MANAGER);
        tokenAmountReceived = amountToWithdraw;

        success = true;
    }
}
