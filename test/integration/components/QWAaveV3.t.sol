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

    address investmentToken = address(_usdc); // Adjust this according to your setup
    address assetToken = address(_aUsdc); // Adjust this according to your setup

    _QWAaveV3 = new QWAaveV3(address(_qwManager), address(_aavePool), investmentToken, assetToken);
    vm.prank(_owner);
    _qwRegistry.registerComponent(address(_QWAaveV3));
  }

  function test_CreateAaveV3() public {
    uint256 amount = 1e12; // 1 million usdc

    // transfer usdc from user to qwManager contract
    vm.prank(_usdcWhale);
    _usdc.transfer(address(_qwManager), amount);
    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_QWAaveV3);

    // execute the investment
    vm.prank(_owner);
    _qwManager.open(targetQWChild, amount);
    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    // Assertions
    assertGe(aUsdcBalanceAfter - aUsdcBalanceBefore, amount);
    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_CloseAaveV3() public {
    // create investment in aave
    test_CreateAaveV3();

    uint256 ratio = 1e8; // 100% ratio

    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_QWAaveV3);

    // close the position
    vm.prank(_owner);
    _qwManager.close(targetQWChild, ratio);

    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    // Assertions
    assertGe(usdcBalanceAfter - usdcBalanceBefore, aUsdcBalanceBefore);
    assertEq(aUsdcBalanceBefore - aUsdcBalanceAfter, aUsdcBalanceBefore);
    assertEq(aUsdcBalanceAfter, 0);
  }
}
