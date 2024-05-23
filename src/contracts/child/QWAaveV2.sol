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
  error UnauthorizedAccess(); // Error for unauthoruzed caller

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
   * @param _callData Encoded function call data (not used in this implementation).
   * @param _tokenAddress Address of the token to be deposited.
   * @param _amount Amount of tokens to be deposited.
   * @return success boolean indicating the success of the transaction.
   */
  function create(
    bytes memory _callData,
    address _tokenAddress,
    uint256 _amount
  ) external override onlyQwManager returns (bool success) {
    if (_callData.length != 0) {
      revert InvalidCallData();
    }

    IERC20 token = IERC20(_tokenAddress);
    token.transferFrom(QW_MANAGER, address(this), _amount);
    token.approve(LENDING_POOL, _amount);

    ILendingPool(LENDING_POOL).deposit(_tokenAddress, _amount, QW_MANAGER, 0);
    return true;
  }

  /**
   * @notice Executes a transaction on AaveV2 pool to withdraw tokens.
   * @dev This function is called by the parent contract to withdraw tokens from the AaveV2 pool.
   * @param _callData Encoded function call data containing the asset and amount to be withdrawn.
   * @return success boolean indicating the success of the transaction.
   */
  function close(bytes memory _callData) external override onlyQwManager returns (bool success) {
    if (_callData.length == 0) {
      revert InvalidCallData();
    }

    (address asset, address lpAsset, uint256 amount) = abi.decode(_callData, (address, address, uint256));

    IERC20 token = IERC20(lpAsset);
    token.transferFrom(QW_MANAGER, address(this), amount);
    token.approve(LENDING_POOL, amount);

    ILendingPool(LENDING_POOL).withdraw(asset, amount, QW_MANAGER);
    return true;
  }
}
