// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWChild} from 'interfaces/IQWChild.sol';
import {ILendingPool} from 'interfaces/aave-v2/ILendingPool.sol';
import {IAToken} from 'interfaces/aave-v2/IAToken.sol';

/**
 * @title AaveV2 Integration for Quant Wealth
 * @notice This contract integrates with AaveV2 protocol for Quant Wealth management.
 */
contract QWAaveV2 is IQWChild {
    // Variables
    address public immutable QW_MANAGER;
    address public immutable LENDING_POOL;
    address public immutable INVESTMENT_TOKEN;
    address public immutable A_INVESTMENT_TOKEN;

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
     * @param _investmentToken The address of the investment token (e.g., USDT).
     * @param _aInvestmentToken The address of the aToken (e.g., aUSDT).
     */
    constructor(
        address _qwManager,
        address _lendingPool,
        address _investmentToken,
        address _aInvestmentToken
    ) {
        QW_MANAGER = _qwManager;
        LENDING_POOL = _lendingPool;
        INVESTMENT_TOKEN = _investmentToken;
        A_INVESTMENT_TOKEN = _aInvestmentToken;
    }

    // Functions
    /**
     * @notice Executes a transaction on AaveV2 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the AaveV2 pool.
     * @param _callData Encoded function call data containing total shares.
     * @param _tokenAmount Amount of tokens to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return shares Number of shares to be allocated to the user in return for investment created.
     */
    function create(
        bytes memory _callData,
        uint256 _tokenAmount
    ) external override onlyQwManager returns (bool success, uint256 shares) {
        (uint256 _totalShares) = abi.decode(_callData, (uint256));

        // Transfer tokens from QWManager to this contract.
        IERC20 token = IERC20(INVESTMENT_TOKEN);
        token.transferFrom(QW_MANAGER, address(this), _tokenAmount);

        // Approve the Aave lending pool to spend the tokens.
        token.approve(LENDING_POOL, _tokenAmount);

        // Calculate price per share before new investment. This is the price that the investment is
        // 'buying' shares of the pool at.
        uint256 sharePrice = pricePerShare(_totalShares);

        // Deposit tokens into Aave.
        ILendingPool(LENDING_POOL).deposit(INVESTMENT_TOKEN, _tokenAmount, address(this), 0);

        // Calculate shares to be issued for the new investment.
        shares = _tokenAmount / sharePrice;

        success = true;
    }

    /**
     * @notice Executes a transaction on AaveV2 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the AaveV2 pool.
     * @param _callData Encoded function call data containing total shares.
     * @param _sharesAmount Amount of shares to be withdrawn.
     * @return success boolean indicating the success of the transaction.
     * @return tokens Number of tokens to be returned to the user in exchange for shares withdrawn.
     */
    function close(
        bytes memory _callData,
        uint256 _sharesAmount
    ) external override onlyQwManager returns (bool success, uint256 tokens) {
        (uint256 _totalShares) = abi.decode(_callData, (uint256));

        if (_sharesAmount > _totalShares) {
            revert InvalidCallData();
        }

        // Calculate the amount of tokens to withdraw based on the shares.
        uint256 totalInvestmentValue = getInvestmentValue();
        // If shares amount < total shares, then the token amount is share * price per share.
        uint256 tokens = (_sharesAmount == _totalShares) ?
            totalInvestmentValue
            : (_sharesAmount * totalInvestmentValue) / _totalShares;

        // Withdraw the tokens from Aave. The number of aTokens to withdraw is equal to underlying tokens received.
        ILendingPool(LENDING_POOL).withdraw(INVESTMENT_TOKEN, tokens, QW_MANAGER);

        // TODO: Send tokens back to QWManager.

        success = true;
    }

    /**
     * @notice Gets the price per share in terms of the specified token.
     * @dev This function calculates the value of one share in terms of the specified token.
     * @param _totalShares The total shares.
     * @return pricePerShare uint256 representing the value of one share in the specified token.
     */
    function pricePerShare(uint256 _totalShares) external view returns (uint256) {
        return _totalShares == 0 ?
            1 * 10 ** token.decimals()
            : getInvestmentValue() / _totalShares;
    }

    /**
     * @notice Gets the total investment value in terms of the specified token.
     * @dev This function calculates the total value of the investment in terms of the specified token.
     * @return investmentValue uint256 representing the total value of the investment in the specified token.
     */
    function getInvestmentValue() public view returns (uint256 investmentValue) {
        // Get the balance of aTokens, which will reflect the principle investment(s) + interest.
        uint256 aTokenBalance = IAToken(A_INVESTMENT_TOKEN).balanceOf(address(this));
        return aTokenBalance;
    }

    /**
     * @notice Gets the address of the Quant Wealth Manager contract.
     * @dev Returns the address of the Quant Wealth Manager contract.
     */
    function QW_MANAGER() external view override returns (address) {
        return qwManager;
    }

    /**
     * @notice Gets the address of the investment token.
     * @dev Returns the address of the token that is initially invested and received once the investment is withdrawn.
     * @return The address of the investment token.
     */
    function INVESTMENT_TOKEN() external view override returns (address) {
        return investmentToken;
    }
}
