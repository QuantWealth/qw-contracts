// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';

// TODO: Inherit and call in constructor of components.

abstract contract QWComponentBase is IQWComponent {
    address public immutable QW_MANAGER;
    address public immutable INVESTMENT_TOKEN;
    address public immutable ASSET_TOKEN;

    // Custom errors
    error InvalidCallData(); // Error for invalid call data
    error UnauthorizedAccess(); // Error for unauthorized caller
    error IncorrectInvestmentTokensReceived(uint256 amount);
    error IncorrectAssetTokensReceived(uint256 amount);

    modifier onlyQwManager() {
        if (msg.sender != QW_MANAGER) {
            revert UnauthorizedAccess();
        }
        _;
    }

    constructor(address _qwManager, address _investmentToken, address _assetToken) {
        QW_MANAGER = _qwManager;
        INVESTMENT_TOKEN = _investmentToken;
        ASSET_TOKEN = _assetToken;
    }

    /**
     * @notice Gets the address of the Quant Wealth Manager contract.
     */
    function getQWManager() external view override returns (address) {
        return QW_MANAGER;
    }

    /**
     * @notice Gets the address of the investment token, the token input and output for the contract.
     */
    function getInvestmentToken() external view override returns (address) {
        return INVESTMENT_TOKEN;
    }

    /**
     * @notice Gets the address of the asset token, the token that is purchased and sold using the investment token.
     */
    function getAssetToken() external view override returns (address) {
        return ASSET_TOKEN;
    }

    /**
     * @notice Checks whether we've received the proper amount of investment tokens.
     */
    function _checkInvestment(uint256 _expectedAmount) internal view {
        if (IERC20(INVESTMENT_TOKEN).balanceOf(address(this)) != _expectedAmount) {
            revert IncorrectInvestmentTokensReceived(balance);
        }
    }

    /**
     * @notice Checks whether we've received any amount of investment tokens.
     */
    function _checkInvestmentAny() internal view returns (uint256) {
        uint256 balance = IERC20(INVESTMENT_TOKEN).balanceOf(address(this));
        if (balance == 0) {
            revert IncorrectInvestmentTokensReceived(balance);
        }
        return balance
    }

    /**
     * @notice Check how much assets we have received upon closing a position.
     */
    function _checkAssets(uint256 _expectedAmount) internal view returns (uint256) {
        uint256 balance = IERC20(ASSET_TOKEN).balanceOf(address(this));
        if (balance != _expectedAmount) {
            revert IncorrectInvestmentTokensReceived(balance);
        }
        return balance;
    }

    /**
     * @notice Checks whether we've received any amount of investment tokens.
     */
    function _checkAssetsAny() internal view returns (uint256) {
        uint256 balance = IERC20(ASSET_TOKEN).balanceOf(address(this));
        if (balance == 0) {
            revert IncorrectAssetTokensReceived(balance);
        }
        return balance;
    }
}