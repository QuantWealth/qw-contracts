// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';

// TODO: Inherit and call in constructor of components.

abstract contract QWComponentBase is IQWComponent {
    address public immutable QW_MANAGER;

    // Custom errors
    error InvalidCallData(); // Error for invalid call data
    error UnauthorizedAccess(); // Error for unauthorized caller
    error IncorrectDepositTokensReceived(uint256 amount);
    error IncorrectAssetTokensReceived(uint256 amount);

    modifier onlyQwManager() {
        if (msg.sender != QW_MANAGER) {
            revert UnauthorizedAccess();
        }
        _;
    }

    constructor(address _qwManager) {
        QW_MANAGER = _qwManager;
    }

    /**
     * @notice Gets the address of the Quant Wealth Manager contract.
     */
    function getQWManager() external view override returns (address) {
        return QW_MANAGER;
    }

    /**
     * @notice Checks whether we've received the proper amount of deposit tokens.
     */
    function _checkDepositTokens(uint256 _expectedAmount, address _depositToken) internal view returns (uint256) {
        uint256 balance = IERC20(_depositToken).balanceOf(address(this));
        if (balance != _expectedAmount) {
            revert IncorrectDepositTokensReceived(balance);
        }
        return balance;
    }

    /**
     * @notice Checks whether we've received any amount of deposit tokens.
     */
    function _checkDepositTokensAny(address _depositToken) internal view returns (uint256) {
        uint256 balance = IERC20(_depositToken).balanceOf(address(this));
        if (balance == 0) {
            revert IncorrectDepositTokensReceived(balance);
        }
        return balance;
    }

    /**
     * @notice Check how much assets we have received upon closing a position.
     */
    function _checkAssets(uint256 _expectedAmount, address _asset) internal view returns (uint256) {
        uint256 balance = IERC20(_asset).balanceOf(address(this));
        if (balance != _expectedAmount) {
            revert IncorrectAssetTokensReceived(balance);
        }
        return balance;
    }

    /**
     * @notice Checks whether we've received any amount of asset tokens.
     */
    function _checkAssetsAny(address _asset) internal view returns (uint256) {
        uint256 balance = IERC20(_asset).balanceOf(address(this));
        if (balance == 0) {
            revert IncorrectAssetTokensReceived(balance);
        }
        return balance;
    }
}
