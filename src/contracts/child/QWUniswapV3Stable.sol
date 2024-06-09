// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;
pragma abicoder v2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IQWChild} from 'interfaces/IQWChild.sol';

import 'interfaces/uniswap-v3/INonfungiblePositionManager.sol';
import 'interfaces/uniswap-v3/ISwapRouter.sol';
import 'interfaces/uniswap-v3/IUniswapV3Pool.sol';

import 'interfaces/uniswap-v3/PeripheryImmutableState.sol';
import 'libraries/uniswap-v3/TickMath.sol';
import 'libraries/uniswap-v3/TransferHelper.sol';

/**
 * @title AaveV3 Integration for Quant Wealth
 * @notice This contract integrates with AaveV3 protocol for Quant Wealth management.
 */
contract QWUniswapV3Stable is IQWChild, Ownable, IERC721Receiver, PeripheryImmutableState {
  // Variables
  address public immutable QW_MANAGER;
  INonfungiblePositionManager public immutable nonfungiblePositionManager;
  IUniswapV3Pool public immutable UNISWAP_POOL;
  uint256 public uniswapPositionTokenId;
  uint128 public liquidityAmount;
  bool public isInitialized;

  // Custom errors
  error InvalidCallData(); // Error for invalid call data
  error UnauthorizedAccess(); // Error for unauthoruzed caller
  error Uninitialized(); // Error for not initialized the position

  modifier onlyQwManager() {
    if (msg.sender != QW_MANAGER) {
      revert UnauthorizedAccess();
    }
    _;
  }

  modifier whenInitialized() {
    if (!isInitialized) {
      revert Uninitialized();
    }
    _;
  }

  /**
   * @dev Constructor to initialize the contract with required addresses.
   * @param _qwManager The address of the Quant Wealth Manager contract.
   */
  constructor(
    address _qwManager,
    address _nonfungiblePositionManager,
    address _factory,
    address _WETH9,
    address _uniswapPool
  ) PeripheryImmutableState(_factory, _WETH9) Ownable(msg.sender) {
    nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
    QW_MANAGER = _qwManager;
    UNISWAP_POOL = IUniswapV3Pool(_uniswapPool);
  }

  /// @notice Calls the mint function defined in periphery, mints the same amount of each token. For this example we are providing 1000 DAI and 1000 USDC in liquidity
  /// @return tokenId The id of the newly minted ERC721
  /// @return liquidity The amount of liquidity for the position
  /// @return amount0 The amount of token0
  /// @return amount1 The amount of token1
  function mintNewPosition(
    uint256 _amount0ToMint,
    uint256 _amount1ToMint
  ) external onlyOwner returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
    // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
    uint256 amount0ToMint = _amount0ToMint;
    uint256 amount1ToMint = _amount1ToMint;
    address token0 = UNISWAP_POOL.token0();
    address token1 = UNISWAP_POOL.token1();
    uint24 poolFee = UNISWAP_POOL.fee();

    // Receive the tokens from sender
    TransferHelper.safeTransferFrom(token0, msg.sender, address(this), amount0ToMint);

    TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1ToMint);

    // Approve the position manager
    TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), amount0ToMint);
    TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), amount1ToMint);

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

    // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized to mint
    (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

    uniswapPositionTokenId = tokenId;
    liquidityAmount = liquidity;

    // Remove allowance and refund in both assets.
    if (amount0 < amount0ToMint) {
      TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), 0);
      uint256 refund0 = amount0ToMint - amount0;
      TransferHelper.safeTransfer(token0, msg.sender, refund0);
    }

    if (amount1 < amount1ToMint) {
      TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), 0);
      uint256 refund1 = amount1ToMint - amount1;
      TransferHelper.safeTransfer(token1, msg.sender, refund1);
    }

    isInitialized = true;
  }

  // Functions
  /**
   * @notice Executes a transaction on AaveV3 pool to deposit tokens.
   * @dev This function is called by the parent contract to deposit tokens into the AaveV3 pool.
   * @param _callData Encoded function call data (not used in this implementation).
   * @param _tokenAddress Address of the token to be deposited.
   * @param _amount Amount of tokens to be deposited.
   * @return success boolean indicating the success of the transaction.
   */
  function create(
    bytes memory _callData,
    address _tokenAddress,
    uint256 _amount
  ) external override onlyQwManager whenInitialized returns (bool success) {
    if (_callData.length != 0) {
      revert InvalidCallData();
    }

    IERC20 token = IERC20(_tokenAddress);
    token.transferFrom(QW_MANAGER, address(this), _amount);

    increaseLiquidityCurrentRange(_amount);
    return true;
  }

  /**
   * @notice Executes a transaction on AaveV3 pool to withdraw tokens.
   * @dev This function is called by the parent contract to withdraw tokens from the AaveV3 pool.
   * @param _callData Encoded function call data containing the asset and amount to be withdrawn.
   * @return success boolean indicating the success of the transaction.
   */
  function close(bytes memory _callData) external override onlyQwManager whenInitialized returns (bool success) {
    if (_callData.length == 0) {
      revert InvalidCallData();
    }

    decreaseLiquidity();
    return true;
  }

  /// @notice Increases liquidity in the current range
  /// @dev Pool must be initialized already to add liquidity
  /// @param amountAdd The amount to add of token0
  function increaseLiquidityCurrentRange(uint256 amountAdd)
    internal
    returns (uint128 liquidity, uint256 amount0, uint256 amount1)
  {
    address token0 = UNISWAP_POOL.token0();
    address token1 = UNISWAP_POOL.token1();

    // Approve the position manager
    TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), amountAdd);
    TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), amountAdd);

    INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
      .IncreaseLiquidityParams({
      tokenId: uniswapPositionTokenId,
      amount0Desired: amountAdd,
      amount1Desired: amountAdd,
      amount0Min: 0,
      amount1Min: 0,
      deadline: block.timestamp
    });

    (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);
    liquidityAmount = liquidity;
  }

  /// @notice A function that decreases the current liquidity by half. An example to show how to call the `decreaseLiquidity` function defined in periphery.
  /// @return amount0 The amount received back in token0
  /// @return amount1 The amount returned back in token1
  function decreaseLiquidity() internal returns (uint256 amount0, uint256 amount1) {
    // get liquidity data for tokenId
    uint128 liquidity = liquidityAmount;
    uint24 poolFee = UNISWAP_POOL.fee();

    // amount0Min and amount1Min are price slippage checks
    // if the amount received after burning is not greater than these minimums, transaction will fail
    INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
      .DecreaseLiquidityParams({
      tokenId: uniswapPositionTokenId,
      liquidity: liquidity,
      amount0Min: 0,
      amount1Min: 0,
      deadline: block.timestamp
    });

    (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
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
