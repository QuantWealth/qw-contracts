// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';
import {QWComponentBase} from './QWComponentBase.sol';
import {ILendingPool} from 'interfaces/aave-v2/ILendingPool.sol';

/**
 * @title AaveV2 Integration for Quant Wealth
 * @notice This contract integrates with AaveV2 protocol for Quant Wealth management.
 */
contract QWAaveV2 is IQWComponent, QWComponentBase {
    // Variables
    address public immutable LENDING_POOL;

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param _qwManager The address of the Quant Wealth Manager contract.
     * @param _lendingPool The address of the AaveV2 pool contract.
     */
    constructor(
        address _qwManager,
        address _lendingPool
    ) QWComponentBase(_qwManager) {
        LENDING_POOL = _lendingPool;
    }

    // Functions
    /**
     * @notice Executes a transaction on AaveV2 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV2 pool.
     * @param _amount Amount of tokens to be deposited.
     * @param _asset The address of the asset token to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived Amount of asset tokens received.
     */
    function open(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        _checkDepositTokens(_amount, _asset);

        // Approve the Aave lending pool to spend the tokens.
        IERC20(_asset).approve(LENDING_POOL, _amount);

        // Deposit tokens into Aave.
        ILendingPool(LENDING_POOL).deposit(_asset, _amount, address(this), 0);

        // Get the balance of aTokens, which will reflect the principal investment(s) + interest.
        // Check to ensure we have received the target asset.
        assetAmountReceived = _checkAssetsAny(_asset);

        // Transfer assets to QWManager.
        IERC20(_asset).transfer(QW_MANAGER, assetAmountReceived);

        success = true;
    }

    /**
     * @notice Executes a transaction on AaveV2 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV2 pool.
     * @param _amount Amount of holdings to be withdrawn.
     * @param _asset The address of the asset token to be withdrawn.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived Number of tokens to be returned to the user in exchange for the withdrawn ratio.
     */
    function close(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        _checkAssets(_amount, _asset);

        // Withdraw the tokens from Aave.
        ILendingPool(LENDING_POOL).withdraw(_asset, _amount, address(this));

        // Check the balance of the investment token received.        
        tokenAmountReceived = _checkDepositTokensAny(_asset);

        // Transfer tokens to QWManager.
        IERC20(_asset).transfer(QW_MANAGER, tokenAmountReceived);

        success = true;
    }
}
