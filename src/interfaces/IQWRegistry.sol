// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Interface for Quant Wealth Integration Contract
 * @author Quant Wealth
 * @notice ...
 */
interface IQWRegistry {

    /// functions
    function registerChild(
        address _child
    ) external;
}
