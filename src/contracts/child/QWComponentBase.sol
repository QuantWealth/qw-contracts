// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IQWChild} from 'interfaces/IQWChild.sol';

// TODO: Inherit and call in constructor of components.

abstract contract QWComponentBase is IQWChild {
    address public immutable QW_MANAGER;
    address public immutable INVESTMENT_TOKEN;
    address public immutable ASSET_TOKEN;

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
}