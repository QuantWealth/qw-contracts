// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IQWChild} from "interfaces/IQWChild.sol";

/**
 * @title Aave Integration for Quant Wealth
 * @notice This contract integrates with Aave protocol for Quant Wealth management.
 */
contract QWAave is IQWChild {
    // Variables
    address public immutable QW_MANAGER;
    address public immutable POOL;

    // Custom errors
    error InvalidCallData(); // Error for invalid call data

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param _qwManager The address of the Quant Wealth Manager contract.
     * @param _pool The address of the Aave pool contract.
     */
    constructor(address _qwManager, address _pool) {
        QW_MANAGER = _qwManager;
        POOL = _pool;
    }

    // Functions
    /**
     * @notice Executes a transaction on Aave pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the Aave pool.
     * @param _callData Encoded function call data (not used in this implementation).
     * @param _tokenAddress Address of the token to be deposited.
     * @param _amount Amount of tokens to be deposited.
     * @return success boolean indicating the success of the transaction.
     */
    function create(
        bytes memory _callData,
        address _tokenAddress,
        uint256 _amount
    ) external override returns (bool success) {
        if (_callData.length != 0) {
            revert InvalidCallData();
        }

        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(QW_MANAGER, address(this), _amount);
        token.approve(POOL, _amount);

        IPool(POOL).supply(_tokenAddress, _amount, QW_MANAGER, 0);
        return true;
    }

    /**
     * @notice Executes a transaction on Aave pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the Aave pool.
     * @param _callData Encoded function call data containing the asset and amount to be withdrawn.
     * @return success boolean indicating the success of the transaction.
     */
    function close(
        bytes memory _callData
    ) external override returns (bool success) {
        if (_callData.length == 0) {
            revert InvalidCallData();
        }

        (address asset, address lpAsset, uint256 amount) = abi.decode(
            _callData,
            (address, address, uint256)
        );

        IERC20 token = IERC20(lpAsset);
        token.transferFrom(QW_MANAGER, address(this), amount);
        token.approve(POOL, amount);

        IPool(POOL).withdraw(asset, amount, QW_MANAGER);
        return true;
    }
}
