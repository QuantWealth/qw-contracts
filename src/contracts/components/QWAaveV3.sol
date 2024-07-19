// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IPool} from '@aave/core-v3/contracts/interfaces/IPool.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';

/**
 * @title AaveV3 Integration for Quant Wealth
 * @notice This contract integrates with AaveV3 protocol for Quant Wealth management.
 */
contract QWAaveV3 is IQWComponent {
    address public immutable QW_MANAGER;
    address public immutable POOL;

    // Custom errors
    error UnauthorizedAccess(); // Error for unauthorized caller

    modifier onlyQwManager() {
        if (msg.sender != QW_MANAGER) {
            revert UnauthorizedAccess();
        }
        _;
    }

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param _qwManager The address of the Quant Wealth Manager contract.
     * @param _pool The address of the AaveV3 pool contract.
     */
    constructor(address _qwManager, address _pool) {
        QW_MANAGER = _qwManager;
        POOL = _pool;
    }

    /**
     * @notice Executes a transaction on AaveV3 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV3 pool.
     * @param _amount Amount of tokens to be deposited.
     * @param _asset Address of the asset to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived Amount of assets received from the deposit.
     */
    function open(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        IERC20(_asset).transferFrom(QW_MANAGER, address(this), _amount);
        IERC20(_asset).approve(POOL, _amount);

        IPool(POOL).supply(_asset, _amount, address(this), 0);
        assetAmountReceived = IERC20(_asset).balanceOf(address(this));

        success = true;
    }

    /**
     * @notice Executes a transaction on AaveV3 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV3 pool.
     * @param _amount Amount to withdraw.
     * @param _asset Address of the asset to be withdrawn.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived Amount of tokens received from the withdrawal.
     */
    function close(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        IPool(POOL).withdraw(_asset, _amount, address(this));
        tokenAmountReceived = IERC20(_asset).balanceOf(address(this));

        IERC20(_asset).transfer(QW_MANAGER, tokenAmountReceived);
        success = true;
    }

    /**
     * @notice Gets the address of the Quant Wealth Manager contract.
     * @return address The address of the Quant Wealth Manager contract.
     */
    function getQWManager() external view override returns (address) {
        return QW_MANAGER;
    }
}
