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
    address public immutable LENDING_POOL;

    // Custom errors
    error InvalidCallData(); // Error for invalid call data
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

    // Functions
    /**
     * @notice Executes a transaction on AaveV2 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV2 pool.
     * @param _callData Encoded function call data containing user address and total shares.
     * @param _tokenAddress Address of the token to be deposited.
     * @param _amount Amount of tokens to be deposited.
     * @return success boolean indicating the success of the transaction.
     */
    function create(
        bytes memory _callData,
        address _tokenAddress,
        uint256 _amount
    ) external override onlyQwManager returns (bool success) {
        (uint256 _totalShares) = abi.decode(_callData, (uint256));

        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(QW_MANAGER, address(this), _amount);
        token.approve(LENDING_POOL, _amount);

        ILendingPool(LENDING_POOL).deposit(_tokenAddress, _amount, address(this), 0);
        uint256 aTokensReceived = IERC20(_tokenAddress).balanceOf(address(this));

        uint256 shares;
        if (_totalShares == 0) {
            shares = aTokensReceived;
        } else {
            uint256 totalPoolValue = getTotalPoolValue(_tokenAddress);
            shares = (aTokensReceived * _totalShares) / totalPoolValue;
        }

        success = true;

        // Encode shares to return back to QWManager
        bytes memory returnData = abi.encode(success, shares);
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }

    /**
     * @notice Executes a transaction on AaveV2 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV2 pool.
     * @param _callData Encoded function call data containing user address, shares amount, and total shares.
     * @return success boolean indicating the success of the transaction.
     */
    function close(
        bytes memory _callData
    ) external override onlyQwManager returns (bool success) {
        (address _user, uint256 _sharesAmount, uint256 _totalShares, address _tokenAddress) = abi.decode(_callData, (address, uint256, uint256, address));

        if (_sharesAmount > _totalShares) {
            revert InvalidCallData();
        }

        uint256 totalSharesValue = getTotalPoolValue(_tokenAddress);
        uint256 amountToWithdraw = (_sharesAmount * totalSharesValue) / _totalShares;

        ILendingPool(LENDING_POOL).withdraw(_tokenAddress, amountToWithdraw, QW_MANAGER);
        success = true;

        // Encode success to return back to QWManager
        bytes memory returnData = abi.encode(success);
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }

    /**
     * @notice Gets the price per share in terms of the specified token.
     * @dev This function calculates the value of one share in terms of the specified token.
     * @param _tokenAddress The address of the token to get the price per share in.
     * @return pricePerShare uint256 representing the value of one share in the specified token.
     */
    function pricePerShare(address _tokenAddress) external view returns (uint256) {
        uint256 totalSharesValue = getTotalPoolValue(_tokenAddress);
        return totalSharesValue / IERC20(_tokenAddress).totalSupply();
    }

    /**
     * @notice Gets the total pool value in terms of the specified token.
     * @dev This function calculates the total value of the pool in terms of the specified token.
     * @param _tokenAddress The address of the token to get the total pool value in.
     * @return poolValue uint256 representing the total value of the pool in the specified token.
     */
    function getTotalPoolValue(address _tokenAddress) public view returns (uint256 poolValue) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }
}
