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
     * @param _pool The address of the AaveV3 pool contract.
     */
    constructor(
        address _qwManager,
        address _pool
    ) QWComponentBase(_qwManager) {
        POOL = _pool;
    }

    // Functions
    /**
     * @notice Executes a transaction on AaveV3 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV3 pool.
     * @param _amount Amount of tokens to be deposited.
     * @param _asset The address of the asset token.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived Amount of assets received from the deposit.
     */
    function open(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        _checkDepositTokens(_amount, _asset);

        IERC20(_asset).approve(POOL, _amount);
        IPool(POOL).supply(_asset, _amount, address(this), 0);

        assetAmountReceived = _checkAssetsAny(_asset);

        // Transfer assets to QWManager.
        IERC20(_asset).transfer(QW_MANAGER, assetAmountReceived);

        success = true;
    }

    /**
     * @notice Executes a transaction on AaveV3 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV3 pool.
     * @param _amount Amount to withdraw.
     * @param _asset The address of the asset token.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived Amount of tokens received from the withdrawal.
     */
    function close(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        _checkAssets(_amount, _asset);

        IPool(POOL).withdraw(_asset, _amount, QW_MANAGER);

        tokenAmountReceived = _checkDepositTokensAny(_asset);

        success = true;
    }
}
