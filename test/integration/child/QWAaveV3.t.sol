// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';

import {IERC20, IPool, IQWChild, QWAaveV3} from 'contracts/child/QWAaveV3.sol';
import {IRewardsController} from '@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol';
import {Test, console2} from 'forge-std/Test.sol';

contract AaveIntegrationV3 is IntegrationBase {
  IPool internal _aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
  IERC20 internal _aUsdc = IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c);
  IRewardsController internal _rewards = IRewardsController(0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb);
  IQWChild internal _QWAaveV3;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    _QWAaveV3 = new QWAaveV3(address(_qwManager), address(_aavePool));
    vm.prank(_owner);
    _qwRegistry.registerChild(address(_QWAaveV3));
  }

  function test_CreateAaveV3() public {
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
    targetQWChild[0] = address(_QWAaveV3);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // execute the investment
    vm.prank(_owner);
    _qwManager.execute(targetQWChild, callDataArr, tokenAddress, amount);
    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    // _aavePool.getUserAccountData(address(_qwManager));
    // address[] memory assetsArr = new address[](2);
    // assetsArr[0] = address(_usdc);
    // assetsArr[1] = address(_aUsdc);
    // _rewards.getAllUserRewards(assetsArr, address(_qwManager));
    // vm.roll(block.number + 1_000_000);
    // _rewards.getUserAccruedRewards(address(_qwManager), assetsArr[1]);
    // _rewards.getUserAccruedRewards(address(_qwManager), assetsArr[0]);
    // _rewards.getRewardsList();
    assertGe(aUsdcBalanceAfter - aUsdcBalanceBefore, amount);
    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_CloseAaveV3() public {
    // create investment in aave
    test_CreateAaveV3();

    uint256 amount = _aUsdc.balanceOf(address(_qwManager));
    bytes memory callData = abi.encode(address(_usdc), address(_aUsdc), amount);

    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_QWAaveV3);

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
