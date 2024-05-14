// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IQWChild} from "interfaces/IQWChild.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

/**
 * @title Interface for Quant Wealth Integration Child Contract
 * @author Quant Wealth
 * @notice ...
 */
contract QWAave is IQWChild {
    /// Variables
    address public immutable qwManager;

    address public immutable pool;

    constructor(address _qwManager, address _pool) {
        qwManager = _qwManager;
        pool = _pool;
    }

    /// functions
    /**
     * @notice ...
     * @dev ...
     * @param _callData ...
     * @param _tokenAddress ...
     * @param _amount ...
     */
    function create(
        bytes memory _callData,
        address _tokenAddress,
        uint256 _amount
    ) external returns (bool success) {
        require(_callData.length > 0, "QWAave: invalid call data");

        IERC20 token = IERC20(_tokenAddress);
        token.approve(pool, _amount);
        
        /// function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        IPool(pool).supply(_tokenAddress, _amount, qwManager, 0);
        return true;
    }

    /**
     * @notice ...
     * @dev ...
     * @param _callData ...
     */
    function close(bytes memory _callData) external returns (bool success) {
        require(_callData.length == 0, "QWAave: invalid call data");

        (address _asset, uint256 _amount) = abi.decode(
            _callData,
            (address, uint256)
        );

        /// function withdraw(address asset, uint256 amount, address to)
        IPool(pool).withdraw(_asset, _amount, qwManager);
        return true;
    }
}
