// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IQWChild} from 'interfaces/IQWChild.sol';
import {ILendingPool} from 'interfaces/aave-v2/ILendingPool.sol';
import {IAToken} from 'interfaces/aave-v2/IAToken.sol';
import {ICurvePool} from 'interfaces/curve/ICurvePool.sol';
import {IPriceOracle} from 'interfaces/IPriceOracle.sol';
import {IUniswapV2Router02} from 'interfaces/uniswap/IUniswapV2Router02.sol';

/**
 * @title AaveV2 Integration for Quant Wealth
 * @notice This contract integrates with AaveV2 protocol for Quant Wealth management.
 */
contract QWAaveV2 is IQWChild {
    // Variables
    address public immutable QW_MANAGER;
    address public immutable LENDING_POOL;
    address public immutable INVESTMENT_TOKEN;
    address public immutable LP_TOKEN;
    address public immutable DW_TOKEN;
    bool public immutable SAME_DW_INVESTMENT_TOKENS;
    uint256 public immutable POOL_SIZE;
    uint256 public immutable DW_POOL_INDEX;
    IPriceOracle public priceOracle;
    ICurvePool public curvePool;
    IUniswapV2Router02 public uniswapRouter;

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
     * @param _lpToken The address of the LP token.
     * @param _dwToken The address of the deposit/withdraw token.
     * @param _priceOracle The address of the price oracle contract.
     * @param _curvePool The address of the Curve pool contract.
     * @param _uniswapRouter The address of the Uniswap router contract.
     * @param _poolSize The size of the Curve pool.
     * @param _dwPoolIndex The index of the DW token in the Curve pool.
     */
    constructor(
        address _qwManager,
        address _lendingPool,
        address _investmentToken,
        address _lpToken,
        address _dwToken,
        address _priceOracle,
        address _curvePool,
        address _uniswapRouter,
        uint256 _poolSize,
        uint256 _dwPoolIndex
    ) {
        QW_MANAGER = _qwManager;
        LENDING_POOL = _lendingPool;
        INVESTMENT_TOKEN = _investmentToken;
        LP_TOKEN = _lpToken;
        DW_TOKEN = _dwToken;
        SAME_DW_INVESTMENT_TOKENS = (_investmentToken == _dwToken);
        priceOracle = IPriceOracle(_priceOracle);
        curvePool = ICurvePool(_curvePool);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        POOL_SIZE = _poolSize;
        DW_POOL_INDEX = _dwPoolIndex;
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

        uint256 dwTokenAmount = _tokenAmount;

        if (!SAME_DW_INVESTMENT_TOKENS) {
            dwTokenAmount = swapInvestmentToDWTokens(_tokenAmount);
        }

        // Prepare amounts array for add_liquidity
        uint256[] memory amounts = new uint256[](POOL_SIZE);
        amounts[DW_POOL_INDEX] = dwTokenAmount;

        // Approve Curve pool to spend the DW tokens.
        IERC20(dwToken).approve(address(curvePool), dwTokenAmount);

        // Calculate share price before adding liquidity.
        uint256 sharePrice = pricePerShare(_totalShares);

        // Add liquidity to the Curve pool.
        curvePool.add_liquidity(amounts, 0);

        // Calculate shares to be issued for the new investment.
        shares = _tokenAmount / sharePrice;

        success = true;
    }

    /**
     * @notice Executes a transaction on Curve pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the Curve pool.
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
        uint256 tokenAmount = (_sharesAmount == _totalShares) ?
            totalInvestmentValue
            : (_sharesAmount * totalInvestmentValue) / _totalShares;

        // Calculate the amount of DW tokens to withdraw from Curve pool.
        uint256 tokens = curvePool.calc_withdraw_one_coin(tokenAmount, int128(DW_POOL_INDEX));

        // Withdraw the tokens from the Curve pool.
        curvePool.remove_liquidity_one_coin(tokens, int128(DW_POOL_INDEX), 0);

        // If SAME_DW_INVESTMENT_TOKENS is false, convert DW tokens to investment tokens.
        if (!SAME_DW_INVESTMENT_TOKENS) {
            tokens = convertDWToInvestmentTokens(tokens);
        }

        // Transfer the tokens to the QW Manager.
        IERC20(DW_TOKEN).transfer(QW_MANAGER, tokens);

        success = true;
    }

    /**
     * @notice Gets the price per share in terms of the specified token.
     * @dev This function calculates the value of one share in terms of the specified token.
     * @param _totalShares The total shares.
     * @return pricePerShare uint256 representing the value of one share in the specified token.
     */
    function pricePerShare(uint256 _totalShares) public view returns (uint256) {
        uint256 decimals = IERC20(LP_TOKEN).decimals();
        return _totalShares == 0 ?
            1 * 10 ** decimals
            : getInvestmentValue() / _totalShares;
    }

    /**
     * @notice Gets the total investment value in terms of the specified token.
     * @dev This function calculates the total value of the investment in terms of the specified token.
     * @return investmentValue uint256 representing the total value of the investment in the specified token.
     */
    function getInvestmentValue() public view returns (uint256 investmentValue) {
        uint256 lpTokenBalance = IAToken(LP_TOKEN).balanceOf(address(this));
        uint256 dwTokenAmount = curvePool.calc_withdraw_one_coin(lpTokenBalance, int128(DW_POOL_INDEX));

        if (SAME_DW_INVESTMENT_TOKENS) {
            investmentValue = dwTokenAmount;
        } else {
            investmentValue = convertDWToInvestmentTokens(dwTokenAmount);
        }
    }

    /**
     * @notice Swaps investment tokens to deposit/withdraw tokens using Uniswap.
     * @param _tokenAmount The amount of investment tokens to be swapped.
     * @return The amount of DW tokens received.
     */
    function swapInvestmentToDWTokens(uint256 _tokenAmount) private returns (uint256) {
        IERC20(INVESTMENT_TOKEN).approve(address(uniswapRouter), _tokenAmount);
        address[] memory path = new address[](2);
        path[0] = INVESTMENT_TOKEN;
        path[1] = DW_TOKEN;

        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        return amounts[1];
    }

    /**
     * @notice Converts DW tokens to investment tokens using a price oracle.
     * @param _dwTokenAmount The amount of DW tokens to be converted.
     * @return The equivalent amount of investment tokens.
     */
    function convertDWToInvestmentTokens(uint256 _dwTokenAmount) private view returns (uint256) {
        uint256 dwTokenPrice = priceOracle.getPrice(DW_TOKEN);
        uint256 investmentTokenPrice = priceOracle.getPrice(INVESTMENT_TOKEN);
        return (_dwTokenAmount * dwTokenPrice) / investmentTokenPrice;
    }

    /**
     * @notice Returns the address of the Quant Wealth Manager contract.
     * @return The address of the Quant Wealth Manager contract.
     */
    function QW_MANAGER() external view override returns (address) {
        return QW_MANAGER;
    }

    /**
     * @notice Returns the address of the investment token.
     * @return The address of the investment token.
     */
    function INVESTMENT_TOKEN() external view override returns (address) {
        return INVESTMENT_TOKEN;
    }
}
