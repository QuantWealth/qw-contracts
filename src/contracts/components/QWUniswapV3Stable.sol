// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;
pragma abicoder v2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';
import {QWComponentBase} from './QWComponentBase.sol';

import 'interfaces/uniswap-v3/INonfungiblePositionManager.sol';
import 'interfaces/uniswap-v3/ISwapRouter.sol';
import 'interfaces/uniswap-v3/IUniswapV3Pool.sol';

import 'interfaces/uniswap-v3/PeripheryImmutableState.sol';
import 'libraries/uniswap-v3/TickMath.sol';
import 'libraries/uniswap-v3/TransferHelper.sol';

/**
 * @title Uniswap V3 Integration for Quant Wealth
 * @notice This contract integrates with Uniswap V3 protocol for Quant Wealth management.
 */
contract QWUniswapV3Stable is IQWComponent, QWComponentBase, Ownable, IERC721Receiver, PeripheryImmutableState {
    // Variables
    INonfungiblePositionManager public immutable NFT_POSITION_MANAGER;
    IUniswapV3Pool public immutable UNISWAP_POOL;
    uint256 public uniswapPositionTokenId;
    uint128 public liquidityAmount;
    bool public isInitialized;

    // Custom errors
    error Uninitialized(); // Error for not initialized the position

    modifier whenInitialized() {
        if (!isInitialized) {
            revert Uninitialized();
        }
        _;
    }

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param _qwManager The address of the Quant Wealth Manager contract.
     * @param _investmentToken The address of the investment token (e.g., USDC).
     * @param _nonfungiblePositionManager The address of the Uniswap V3 non-fungible position manager contract.
     * @param _factory The address of the Uniswap V3 factory contract.
     * @param _WETH9 The address of the WETH9 contract.
     * @param _uniswapPool The address of the Uniswap V3 pool contract.
     */
    constructor(
        address _qwManager,
        address _investmentToken,
        address _nonfungiblePositionManager,
        address _factory,
        address _WETH9,
        address _uniswapPool
    )
    PeripheryImmutableState(_factory, _WETH9)
    Ownable(msg.sender)
    QWComponentBase(_qwManager, _investmentToken, _nonfungiblePositionManager) {
        NFT_POSITION_MANAGER = INonfungiblePositionManager(_nonfungiblePositionManager);
        QW_MANAGER = _qwManager;
        UNISWAP_POOL = IUniswapV3Pool(_uniswapPool);
    }

    /**
     * @notice Executes a transaction on Uniswap V3 pool to deposit tokens.
     * @dev This function is called by the parent contract to deposit tokens into the Uniswap V3 pool.
     * @param _amount Amount of tokens to be deposited.
     * @return success boolean indicating the success of the transaction.
     * @return assetAmountReceived The amount of assets received from the deposit.
     */
    function open(
        uint256 _amount
    ) external override onlyQwManager whenInitialized returns (bool success, uint256 assetAmountReceived) {
        _checkInvestment(_amount);
        // TODO: Check to ensure NFT position manager was transferred
        // TODO: INVESMENT_TOKEN needs to be swapped for token0, token1 as needed, and updated amount for each
        // passed into increaseLiquidityCurrentRange

        (uint256 liquidity, uint256 amount0, uint256 amount1) = increaseLiquidityCurrentRange(_amount);

        assetAmountReceived = uint256(liquidity); // TODO: Is liquidity the total amount or the amount received?

        // TODO: Send NFT to QWManager

        success = true;
    }

    /**
     * @notice Executes a transaction on Uniswap V3 pool to withdraw tokens.
     * @dev This function is called by the parent contract to withdraw tokens from the Uniswap V3 pool.
     * @param _amount Amount of holdings to withdraw.
     * @return success boolean indicating the success of the transaction.
     * @return tokenAmountReceived The amount of tokens received from the withdrawal.
     */
    function close(
        uint256 _amount
    ) external override onlyQwManager whenInitialized returns (bool success, uint256 tokenAmountReceived) {
        // TODO: Check to ensure amount is present on the NFT position manager
        // TODO: Check to ensure NFT position manager was transferred

        (uint256 amount0, uint256 amount1) = decreaseLiquidity(); // TODO: decreaseLiquidity should take _amount
        tokenAmountReceived = amount0 + amount1;
        // TODO: This is incorrect! We should check to see if token0 or token1 are already INVESMENT_TOKEN, if either
        // are not the INVESMENT_TOKEN, swap them for the INVESMENT_TOKEN using a swap router

        // TODO: Transfer NFT back to QWManager.
        // TODO: Transfer tokens back to QWManager.

        success = true;
    }

    /**
     * @notice Calls the mint function defined in periphery, mints the same amount of each token.
     * @param _amount0ToMint The amount of token0 to mint.
     * @param _amount1ToMint The amount of token1 to mint.
     * @return tokenId The id of the newly minted ERC721.
     * @return liquidity The amount of liquidity for the position.
     * @return amount0 The amount of token0.
     * @return amount1 The amount of token1.
     */
    function mintNewPosition(
        uint256 _amount0ToMint,
        uint256 _amount1ToMint
    ) external onlyOwner returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        uint256 amount0ToMint = _amount0ToMint;
        uint256 amount1ToMint = _amount1ToMint;
        address token0 = UNISWAP_POOL.token0();
        address token1 = UNISWAP_POOL.token1();
        uint24 poolFee = UNISWAP_POOL.fee();

        // Transfer the tokens from sender
        TransferHelper.safeTransferFrom(token0, msg.sender, address(this), amount0ToMint);
        TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1ToMint);

        // Approve the position manager
        TransferHelper.safeApprove(token0, address(NFT_POSITION_MANAGER), amount0ToMint);
        TransferHelper.safeApprove(token1, address(NFT_POSITION_MANAGER), amount1ToMint);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: poolFee,
            tickLower: TickMath.MIN_TICK + 2,
            tickUpper: TickMath.MAX_TICK - 2,
            amount0Desired: amount0ToMint,
            amount1Desired: amount1ToMint,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        (tokenId, liquidity, amount0, amount1) = NFT_POSITION_MANAGER.mint(params);

        uniswapPositionTokenId = tokenId;
        liquidityAmount = liquidity;

        // Remove allowance and refund in both assets.
        if (amount0 < amount0ToMint) {
            TransferHelper.safeApprove(token0, address(NFT_POSITION_MANAGER), 0);
            uint256 refund0 = amount0ToMint - amount0;
            TransferHelper.safeTransfer(token0, msg.sender, refund0);
        }

        if (amount1 < amount1ToMint) {
            TransferHelper.safeApprove(token1, address(NFT_POSITION_MANAGER), 0);
            uint256 refund1 = amount1ToMint - amount1;
            TransferHelper.safeTransfer(token1, msg.sender, refund1);
        }

        isInitialized = true;
    }

    /**
     * @notice Increases liquidity in the current range.
     * @dev Pool must be initialized already to add liquidity.
     * @param amountAdd The amount to add of token0.
     * @return liquidity The amount of liquidity.
     * @return amount0 The amount of token0.
     * @return amount1 The amount of token1.
     */
    function increaseLiquidityCurrentRange(uint256 amountAdd)
        internal
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        address token0 = UNISWAP_POOL.token0();
        address token1 = UNISWAP_POOL.token1();

        // Approve the position manager
        TransferHelper.safeApprove(token0, address(NFT_POSITION_MANAGER), amountAdd);
        TransferHelper.safeApprove(token1, address(NFT_POSITION_MANAGER), amountAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams({
            tokenId: uniswapPositionTokenId,
            amount0Desired: amountAdd,
            amount1Desired: amountAdd,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = NFT_POSITION_MANAGER.increaseLiquidity(params);
        liquidityAmount = liquidity;
    }

    /**
     * @notice Decreases the current liquidity by half.
     * @return amount0 The amount received back in token0.
     * @return amount1 The amount returned back in token1.
     */
    function decreaseLiquidity() internal returns (uint256 amount0, uint256 amount1) {
        // get liquidity data for tokenId
        uint128 liquidity = liquidityAmount;
        uint24 poolFee = UNISWAP_POOL.fee();

        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: uniswapPositionTokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        (amount0, amount1) = NFT_POSITION_MANAGER.decreaseLiquidity(params);
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
