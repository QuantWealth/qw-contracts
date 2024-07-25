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
     * @param _comet The address of the Compound comet contract.
     */
    constructor(
        address _qwManager,
        address _comet
    ) QWComponentBase(_qwManager) {
        COMET = _comet;
    }

    // Functions
    /**
     * @notice Executes a transaction on Compound comet to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the Compound comet.
     * @param _amount Amount of tokens to be deposited.
     * @param _asset The address of the asset token to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived The amount of asset tokens received from the deposit.
     */
    function open(
        uint256 _amount,
        address _asset
    ) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        _checkDepositTokens(_amount, _asset);

        IERC20(_asset).approve(COMET, _amount);

        // Perform the supply to Compound.
        IComet(COMET).supplyTo(address(this), _asset, _amount);

        assetAmountReceived = _checkAssetsAny(_asset);
        success = true;

        // Transfer assets to QWManager.
        IERC20(_asset).transfer(QW_MANAGER, assetAmountReceived);
    }

    /**
     * @notice Executes a transaction on Compound comet to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the Compound comet.
     * @param _amount Amount of asset tokens to withdraw.
     * @param _asset The address of the asset token.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived The amount of tokens received from the withdrawal.
     */
    function close(
        uint256 _amount,
        address _asset
    ) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        _checkAssets(_amount, _asset);

        // Perform the withdraw from Compound.
        IComet(COMET).withdrawTo(address(this), _asset, _amount);

        tokenAmountReceived = _checkDepositTokensAny(_asset);
        success = true;

        // Transfer tokens to QWManager.
        IERC20(_asset).transfer(QW_MANAGER, tokenAmountReceived);
    }
}
