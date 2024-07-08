// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {IERC20, ILendingPool, QWAaveV2} from 'contracts/components/QWAaveV2.sol';

import {IIncentivesController} from 'interfaces/aave-v2/IIncentivesController.sol';

contract AaveIntegrationV2 is IntegrationBase {
  ILendingPool internal _aaveLendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  IERC20 internal _aUsdc = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
  IIncentivesController internal _rewards = IIncentivesController(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
  QWAaveV2 internal _QWAaveV2;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    _QWAaveV2 = new QWAaveV2(address(_qwManager), address(_aaveLendingPool), address(_usdc), address(_aUsdc));
    vm.prank(_owner);
    _qwRegistry.registerComponent(address(_QWAaveV2));
  }

  function test_OpenAaveV2() public {
    uint256 amount = 1e12; // 1 million usdc

    // Transfer usdc from user to qwManager contract
    vm.prank(_usdcWhale);
    _usdc.transfer(address(_qwManager), amount);
    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_QWAaveV2));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create OpenBatch array
    IQWManager.OpenBatch[] memory batches = new IQWManager.OpenBatch[](1);
    batches[0] = IQWManager.OpenBatch({
        protocol: address(_QWAaveV2),
        amount: amount
    });

    // Execute the investment
    vm.prank(_owner);
    _qwManager.open(batches);
    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_QWAaveV2));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    // Example for getting rewards
    vm.roll(19_921_492);
    _rewards.getUserUnclaimedRewards(0xD102D2A88Fa2d23DC4048f559aA05579F2b3d47f);
    _rewards.getUserUnclaimedRewards(address(_qwManager));

    assertGe(aUsdcBalanceAfter - aUsdcBalanceBefore, amount);
    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_CloseAaveV2() public {
    // Create investment in Aave
    test_OpenAaveV2();

    uint256 amount = _aUsdc.balanceOf(address(_QWAaveV2));
    uint256 ratio = 1e8; // 100% withdrawal

    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_QWAaveV2));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create CloseBatch array
    IQWManager.CloseBatch[] memory batches = new IQWManager.CloseBatch[](1);
    batches[0] = IQWManager.CloseBatch({
        protocol: address(_QWAaveV2),
        ratio: ratio
    });

    // Close the position
    vm.prank(_owner);
    _qwManager.close(batches);

    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_QWAaveV2));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertGe(usdcBalanceAfter - usdcBalanceBefore, amount);
    assertEq(aUsdcBalanceBefore - aUsdcBalanceAfter, amount);
    assertEq(aUsdcBalanceAfter, 0);
  }
}
