// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IComet} from 'interfaces/IComet.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';
import {QWComponentBase} from './QWComponentBase.sol';

/**
 * @title Compound Integration for Quant Wealth
 * @notice This contract integrates with Compound protocol for Quant Wealth management.
 */
contract QWCompound is IQWComponent, QWComponentBase {
    // Variables
    address public immutable COMET;

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param _qwManager The address of the Quant Wealth Manager contract.
     * @param _investmentToken The address of the investment token (e.g., USDC).
     * @param _assetToken The address of the asset token received from Compound (e.g., cUSDC).
     * @param _comet The address of the Compound comet contract.
     */
    constructor(
        address _qwManager,
        address _investmentToken,
        address _assetToken,
        address _comet
    ) QWComponentBase(_qwManager, _investmentToken, _assetToken) {
        COMET = _comet;
    }

    // Functions
    /**
     * @notice Executes a transaction on Compound comet to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the Compound comet.
     * @param _amount Amount of tokens to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived The amount of asset tokens received from the deposit.
     */
    function open(
        uint256 _amount
    ) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        IERC20 token = IERC20(INVESTMENT_TOKEN);
        token.transferFrom(QW_MANAGER, address(this), _amount);
        token.approve(COMET, _amount);

        // Perform the supply to Compound and get the current balance before and after to calculate the received amount
        uint256 balanceBefore = IERC20(ASSET_TOKEN).balanceOf(address(this));
        IComet(COMET).supplyTo(address(this), INVESTMENT_TOKEN, _amount);
        uint256 balanceAfter = IERC20(ASSET_TOKEN).balanceOf(address(this));

        assetAmountReceived = balanceAfter - balanceBefore;
        success = true;
    }

    /**
     * @notice Executes a transaction on Compound comet to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the Compound comet.
     * @param _ratio Percentage of holdings to be withdrawn, with 8 decimal places for precision.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived The amount of tokens received from the withdrawal.
     */
    function close(
        uint256 _ratio
    ) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        uint256 totalHoldings = IERC20(ASSET_TOKEN).balanceOf(address(this));
        uint256 amountToWithdraw = (totalHoldings * _ratio) / 1e8;

        // Perform the withdraw from Compound and get the current balance before and after to calculate the received amount
        uint256 balanceBefore = IERC20(INVESTMENT_TOKEN).balanceOf(address(this));
        IComet(COMET).withdrawTo(address(this), INVESTMENT_TOKEN, amountToWithdraw);
        uint256 balanceAfter = IERC20(INVESTMENT_TOKEN).balanceOf(address(this));

        tokenAmountReceived = balanceAfter - balanceBefore;
        success = true;
    }
}
