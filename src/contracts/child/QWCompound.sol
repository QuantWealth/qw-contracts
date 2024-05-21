// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IComet} from 'interfaces/IComet.sol';
import {IQWChild} from 'interfaces/IQWChild.sol';

/**
 * @title Compound Integration for Quant Wealth
 * @notice This contract integrates with Compound protocol for Quant Wealth management.
 */
contract QWCompound is IQWChild {
  // Variables
  address public immutable QW_MANAGER;
  address public immutable COMET;

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
   * @param _comet The address of the Compound comet contract.
   */
  constructor(address _qwManager, address _comet) {
    QW_MANAGER = _qwManager;
    COMET = _comet;
  }

  // Functions
  /**
   * @notice Executes a transaction on Compound comet to deposit tokens.
   * @dev This function is called by the parent contract to deposit tokens into the Compound comet.
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
    token.approve(COMET, _amount);

    IComet(COMET).supplyTo(QW_MANAGER, _tokenAddress, _amount);
    return true;
  }

  /**
   * @notice Executes a transaction on Compound comet to withdraw tokens.
   * @dev This function is called by the parent contract to withdraw tokens from the Compound comet.
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
    token.approve(COMET, amount);

    IComet(COMET).withdrawTo(QW_MANAGER, asset, amount);
    return true;
  }
}
