// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';
import {IERC20, ILendingPool, IQWChild, QWAaveV2} from 'contracts/child/QWAaveV2.sol';

import {IIncentivesController} from 'interfaces/aave-v2/IIncentivesController.sol';

contract AaveIntegrationV2 is IntegrationBase {
  ILendingPool internal _aaveLendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  IERC20 internal _aUsdc = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
  IIncentivesController internal _rewards = IIncentivesController(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  IQWChild internal _QWAaveV2;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    _QWAaveV2 = new QWAaveV2(address(_qwManager), address(_aaveLendingPool));
    vm.prank(_owner);
    _qwRegistry.registerChild(address(_QWAaveV2));
  }

  function test_CreateAaveV2() public {
    uint256 amount = 1e12; // 1 million usdc
    bytes memory callData = '';
    address tokenAddress = address(_usdc);

    // transfer usdc from user to qwManager contract
    vm.prank(_usdcWhale);
    _usdc.transfer(address(_qwManager), amount);
    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_QWAaveV2);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // execute the investment
    vm.prank(_owner);
    _qwManager.execute(targetQWChild, callDataArr, tokenAddress, amount);
    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    // example for getting rewards
    vm.roll(19_921_492);
    _rewards.getUserUnclaimedRewards(0xD102D2A88Fa2d23DC4048f559aA05579F2b3d47f);
    _rewards.getUserUnclaimedRewards(address(_qwManager));

    assertGe(aUsdcBalanceAfter - aUsdcBalanceBefore, amount);
    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_CloseAaveV2() public {
    // create investment in aave
    test_CreateAaveV2();

    uint256 amount = _aUsdc.balanceOf(address(_qwManager));
    bytes memory callData = abi.encode(address(_usdc), address(_aUsdc), amount);

    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_QWAaveV2);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // close the position
    vm.prank(_owner);
    _qwManager.close(targetQWChild, callDataArr);

    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertGe(usdcBalanceAfter - usdcBalanceBefore, amount);
    assertEq(aUsdcBalanceBefore - aUsdcBalanceAfter, amount);
    assertEq(aUsdcBalanceAfter, 0);
  }
}
