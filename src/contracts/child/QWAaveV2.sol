// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWChild} from 'interfaces/IQWChild.sol';
import {ILendingPool} from 'interfaces/aave-v2/ILendingPool.sol';

/**
 * @title AaveV2 Integration for Quant Wealth
 * @notice This contract integrates with AaveV2 protocol for Quant Wealth management.
 */
contract QWAaveV2 is IQWChild {
    // Variables
    address public immutable QW_MANAGER;
    address public immutable INVESTMENT_TOKEN;
    address public immutable ASSET_TOKEN;
    address public immutable LENDING_POOL;

    // Custom errors
    error InvalidCallData(); // Error for invalid call data
    error UnauthorizedAccess(); // Error for unauthorized caller
    error NoInvestmentTokensReceived();
    error NoAssetTokensReceived();

    modifier onlyQwManager() {
        if (msg.sender != QW_MANAGER) {
            revert UnauthorizedAccess();
        }
        _;
    }

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param _qwManager The address of the Quant Wealth Manager contract.
     * @param _lendingPool The address of the AaveV2 pool contract.
     * @param _investmentToken The address of the investment token (e.g., USDT).
     * @param _assetToken The address of the corresponding aToken (e.g., aUSDT).
     */
    constructor(
        address _qwManager,
        address _lendingPool,
        address _investmentToken,
        address _assetToken
    ) {
        QW_MANAGER = _qwManager;
        LENDING_POOL = _lendingPool;
        INVESTMENT_TOKEN = _investmentToken;
        ASSET_TOKEN = _assetToken;
    }

    // Functions
    /**
     * @notice Executes a transaction on AaveV2 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV2 pool.
     * @param _amount Amount of tokens to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived Amount of asset tokens received.
     */
    function open(uint256 _amount) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        // Transfer tokens from QWManager to this contract.
        // IERC20 token = IERC20(INVESTMENT_TOKEN);
        // token.transferFrom(QW_MANAGER, address(this), _amount);
        // Check whether we have been transferred the tokens to spend.
        if (IERC20(INVESTMENT_TOKEN).balanceOf(address(this)) == 0) {
            revert NoInvestmentTokensReceived();
        }

        // Approve the Aave lending pool to spend the tokens.
        IERC20(INVESTMENT_TOKEN).approve(LENDING_POOL, _amount);

        // Deposit tokens into Aave.
        ILendingPool(LENDING_POOL).deposit(INVESTMENT_TOKEN, _amount, address(this), 0);

        // Get the balance of aTokens, which will reflect the principle investment(s) + interest.
        assetAmountReceived = IERC20(ASSET_TOKEN).balanceOf(address(this));

        // Check to ensure we have received the target asset.
        if (assetAmountReceived == 0) {
            revert NoAssetTokensReceived();
        }

        // Transfer assets to QWManager.
        IERC20(ASSET_TOKEN).transfer(QW_MANAGER, assetAmountReceived);

        success = true;
    }

    /**
     * @notice Executes a transaction on AaveV2 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV2 pool.
     * @param _amount Amount of holdings to be withdrawn.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived Number of tokens to be returned to the user in exchange for the withdrawn ratio.
     */
    function close(uint256 _amount) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        if (IERC20(ASSET_TOKEN).balanceOf(address(this)) == 0) {
            revert NoAssetTokensReceived();
        }

        // Withdraw the tokens from Aave.
        ILendingPool(LENDING_POOL).withdraw(INVESTMENT_TOKEN, _amount, address(this));

        // Check the balance of the investment token received.
        tokenAmountReceived = IERC20(INVESTMENT_TOKEN).balanceOf(address(this));
        if (tokenAmountReceived == 0) {
            revert NoInvestmentTokensReceived();
        }

        // Transfer tokens to QWManager.
        IERC20(INVESTMENT_TOKEN).transfer(QW_MANAGER, tokenAmountReceived);

        success = true;
    }
}
