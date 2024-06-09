// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';
import {Test, console2} from 'forge-std/Test.sol';

import {
  IERC20,
  INonfungiblePositionManager,
  IQWChild,
  IUniswapV3Pool,
  QWUniswapV3Stable
} from 'contracts/child/QWUniswapV3Stable.sol';

contract UniswapV3stableIntegration is IntegrationBase {
  IUniswapV3Pool internal _uniswapUSDCUSDTPool = IUniswapV3Pool(0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf);
  INonfungiblePositionManager internal _nonfungiblePositionManager =
    INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  QWUniswapV3Stable internal _QWUniswapV3Stable;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    address _factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    vm.startPrank(_owner);
    _QWUniswapV3Stable = new QWUniswapV3Stable(
      address(_qwManager), address(_nonfungiblePositionManager), _factory, _weth, address(_uniswapUSDCUSDTPool)
    );
    _qwRegistry.registerChild(address(_QWUniswapV3Stable));
    vm.stopPrank();

    uint256 amount = 1e10; // 10k usdc/usdt
    vm.prank(_usdcWhale);
    _usdc.transfer(address(_owner), amount);
    vm.prank(_usdtWhale);
    _usdt.transfer(address(_owner), amount);

    vm.startPrank(_owner);
    // minting new position
    _usdc.approve(address(_QWUniswapV3Stable), amount);
    _usdt.approve(address(_QWUniswapV3Stable), amount);
    _QWUniswapV3Stable.mintNewPosition(amount, amount);
    vm.stopPrank();
  }

  function test_CreateUniswapV3Stable() public {
    uint256 amount = 1e10; // 10k usdc
    bytes memory callData = '';
    address tokenAddress = address(_usdc);

    vm.prank(_usdtWhale);
    _usdt.transfer(address(_QWUniswapV3Stable), amount);

    // transfer usdc from user to qwManager contract
    vm.prank(_usdcWhale);
    _usdc.transfer(address(_qwManager), amount);
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_QWUniswapV3Stable);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // execute the investment
    vm.prank(_owner);
    _qwManager.execute(targetQWChild, callDataArr, tokenAddress, amount);
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_CloseUniswapV3Stable() public {
    // create investment in uniswap
    test_CreateUniswapV3Stable();

    bytes memory callData = abi.encode(address(_usdc), address(_usdc), 0);

    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create dynamic arrays with one element each
    address[] memory targetQWChild = new address[](1);
    targetQWChild[0] = address(_QWUniswapV3Stable);

    bytes[] memory callDataArr = new bytes[](1);
    callDataArr[0] = callData;

    // close the position
    vm.prank(_owner);
    _qwManager.close(targetQWChild, callDataArr);

    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));
  }
}
