// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';

import {IRewardsController} from '@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol';
import {IERC20, IPool, QWAaveV3} from 'contracts/components/QWAaveV3.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';

contract AaveIntegrationV3 is IntegrationBase {
  IPool internal _aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
  IERC20 internal _aUsdc = IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c);
  IRewardsController internal _rewards = IRewardsController(0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb);
  IQWComponent internal _QWAaveV3;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    _QWAaveV3 = new QWAaveV3(address(_qwManager), address(_aavePool));
    vm.prank(_owner);
    _qwRegistry.registerComponent(address(_QWAaveV3));
  }

  function test_AaveV3__openShouldWork() public {
    uint256 amount = 1e12; // 1 million usdc

    // Transfer usdc from user to qwManager contract
    vm.prank(_usdcWhale);
    _usdc.transfer(address(_qwManager), amount);
    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_QWAaveV3));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create OpenBatch array
    IQWManager.OpenBatch[] memory batches = new IQWManager.OpenBatch[](1);
    batches[0] = IQWManager.OpenBatch({
        component: address(_QWAaveV3),
        token: address(_usdc),
        amount: amount,
        asset: address(_aUsdc)
    });

    // Execute the investment
    vm.prank(_owner);
    _qwManager.open(batches);
    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_QWAaveV3));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    // Example for getting rewards
    // vm.roll(19_921_492);
    // _rewards.getUserUnclaimedRewards(0xD102D2A88Fa2d23DC4048f559aA05579F2b3d47f);
    // _rewards.getUserUnclaimedRewards(address(_qwManager));

    assertGe(aUsdcBalanceAfter - aUsdcBalanceBefore, amount);
    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_AaveV3__closeShouldWork() public {
    // Create investment in Aave
    test_AaveV3__openShouldWork();

    uint256 amount = _aUsdc.balanceOf(address(_QWAaveV3));
    uint256 ratio = 1e8; // 100% withdrawal

    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_QWAaveV3));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create CloseBatch array
    IQWManager.CloseBatch[] memory batches = new IQWManager.CloseBatch[](1);
    batches[0] = IQWManager.CloseBatch({
        component: address(_QWAaveV3),
        ratio: ratio,
        asset: address(_aUsdc)
    });

    // Close the position
    vm.prank(_owner);
    _qwManager.close(batches);

    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_QWAaveV3));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertGe(usdcBalanceAfter - usdcBalanceBefore, amount);
    assertEq(aUsdcBalanceBefore - aUsdcBalanceAfter, amount);
    assertEq(aUsdcBalanceAfter, 0);
  }
}
