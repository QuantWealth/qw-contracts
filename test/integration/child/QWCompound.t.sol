// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';
import {IComet, IERC20, IQWChild, QWCompound} from 'contracts/child/QWCompound.sol';
import {Test, console2} from 'forge-std/Test.sol';

contract CompoundIntegration is IntegrationBase {
  IComet internal _compoundV3Comet = IComet(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
  IERC20 internal _cUsdcV3 = IERC20(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
  IQWChild internal _qwCompound;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    _qwCompound = new QWCompound(address(_qwManager), address(_compoundV3Comet));
    _qwRegistry.registerChild(address(_qwCompound));
  }

  function test_CreateCompound() public {
    vm.startPrank(_usdcWhale);
    uint256 amount = 1e12; // 1 million usdc
    bytes memory callData = '';
    address tokenAddress = address(_usdc);

    uint256 supplyFee = 1; // supply fees taken by compound

    // transfer dai from user to qwManager contract
    _usdc.transfer(address(_qwManager), amount);

    uint256 cUsdcV3BalanceBefore = _cUsdcV3.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_qwCompound);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // execute the investment
    _qwManager.execute(targetQWChild, callDataArr, tokenAddress, amount);
    uint256 cUsdcV3BalanceAfter = _cUsdcV3.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertGe(cUsdcV3BalanceAfter - cUsdcV3BalanceBefore, amount - supplyFee);
    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
    vm.stopPrank();
  }

  function test_CloseCompound() public {
    // create investment in compound
    test_CreateCompound();

    vm.startPrank(_usdcWhale);

    /**
     * when baseToken == lpAsset
     * to withdraw collateral, amount needs to be type(uint256).max
     * else it tries to borrow the asset
     */
    uint256 amount = type(uint256).max;
    bytes memory callData = abi.encode(address(_usdc), address(_cUsdcV3), amount);
    uint256 withdrawFee = 2; // withdraw fees taken by compound

    uint256 cUsdcV3BalanceBefore = _cUsdcV3.balanceOf(address(_qwManager));
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_qwCompound);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // close the position
    _qwManager.close(targetQWChild, callDataArr);

    uint256 cUsdcV3BalanceAfter = _cUsdcV3.balanceOf(address(_qwManager));
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertGe(usdcBalanceAfter - usdcBalanceBefore, cUsdcV3BalanceBefore - withdrawFee);
    assertEq(cUsdcV3BalanceAfter, 0);
    vm.stopPrank();
  }
}
