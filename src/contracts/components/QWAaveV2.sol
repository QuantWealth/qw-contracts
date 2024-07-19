// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';
import {ILendingPool} from 'interfaces/aave-v2/ILendingPool.sol';

/**
 * @title AaveV2 Integration for Quant Wealth
 * @notice This contract integrates with AaveV2 protocol for Quant Wealth management.
 */
contract QWAaveV2 is IQWComponent {
    address public immutable QW_MANAGER;
    address public immutable LENDING_POOL;

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
     * @param _lendingPool The address of the AaveV2 pool contract.
     */
    constructor(address _qwManager, address _lendingPool) {
        QW_MANAGER = _qwManager;
        LENDING_POOL = _lendingPool;
    }

    /**
     * @notice Executes a transaction on AaveV2 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV2 pool.
     * @param _amount Amount of tokens to be deposited.
     * @param _asset Address of the asset to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived Amount of asset tokens received.
     */
    function open(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 assetAmountReceived) {
        IERC20(_asset).transferFrom(QW_MANAGER, address(this), _amount);
        IERC20(_asset).approve(LENDING_POOL, _amount);

        ILendingPool(LENDING_POOL).deposit(_asset, _amount, address(this), 0);
        assetAmountReceived = IERC20(_asset).balanceOf(address(this));

        success = true;
    }

    /**
     * @notice Executes a transaction on AaveV2 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV2 pool.
     * @param _amount Amount of holdings to be withdrawn.
     * @param _asset Address of the asset to be withdrawn.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived Number of tokens to be returned to the user in exchange for the withdrawn ratio.
     */
    function close(uint256 _amount, address _asset) external override onlyQwManager returns (bool success, uint256 tokenAmountReceived) {
        ILendingPool(LENDING_POOL).withdraw(_asset, _amount, address(this));
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
