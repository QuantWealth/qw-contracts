// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';
import {IERC20, IPool, IQWChild, QWAave} from 'contracts/child/QWAave.sol';
import {Test, console2} from 'forge-std/Test.sol';

contract AaveIntegration is IntegrationBase {
  IPool internal _aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
  IERC20 internal _aUsdc = IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c);
  IQWChild internal _qwAave;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    _qwAave = new QWAave(address(_qwManager), address(_aavePool));
    vm.prank(_owner);
    _qwRegistry.registerChild(address(_qwAave));
  }

  function test_CreateAave() public {
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
    targetQWChild[0] = address(_qwAave);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // execute the investment
    vm.prank(_owner);
    _qwManager.execute(targetQWChild, callDataArr, tokenAddress, amount);
    uint256 aUsdcBalanceAfter = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertGe(aUsdcBalanceAfter - aUsdcBalanceBefore, amount);
    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_CloseAave() public {
    // create investment in aave
    test_CreateAave();

    uint256 amount = _aUsdc.balanceOf(address(_qwManager));
    bytes memory callData = abi.encode(address(_usdc), address(_aUsdc), amount);

    uint256 aUsdcBalanceBefore = _aUsdc.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_qwAave);

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
