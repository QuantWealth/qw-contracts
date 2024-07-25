// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';
import {Test, console2} from 'forge-std/Test.sol';

import {
  IERC20,
  INonfungiblePositionManager,
  IQWComponent,
  IUniswapV3Pool,
  QWUniswapV3Stable
} from 'contracts/components/QWUniswapV3Stable.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';

contract UniswapV3stableIntegration is IntegrationBase {
  IUniswapV3Pool internal _uniswapUSDCUSDTPool = IUniswapV3Pool(0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf);
  INonfungiblePositionManager internal _nonfungiblePositionManager =
    INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  QWUniswapV3Stable internal _QWUniswapV3Stable;
  address internal depositToken;

  function setUp() public virtual override {
    IntegrationBase.setUp();

    depositToken = address(0x123);

    address _factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    vm.startPrank(_owner);
    _QWUniswapV3Stable = new QWUniswapV3Stable(
      address(_qwManager), address(_nonfungiblePositionManager), _factory, _weth, address(_uniswapUSDCUSDTPool)
    );
    _qwRegistry.registerComponent(address(_QWUniswapV3Stable));
    vm.stopPrank();

    uint256 amount = 1e10; // 10k usdc/usdt
    vm.prank(_usdcWhale);
    _usdc.transfer(address(_owner), amount);
    vm.prank(_usdtWhale);
    _usdt.transfer(address(_owner), amount);

    vm.startPrank(_owner);
    // Minting new position
    _usdc.approve(address(_QWUniswapV3Stable), amount);
    _usdt.approve(address(_QWUniswapV3Stable), amount);
    _QWUniswapV3Stable.mintNewPosition(amount, amount);
    vm.stopPrank();
  }

  function test_UniswapV3Stable__openShouldWork() public {
    uint256 amount = 1e10; // 10k usdc
    address tokenAddress = address(_usdc);

    vm.prank(_usdcWhale);
    _usdc.transfer(address(_qwManager), amount);
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create OpenBatch array
    IQWManager.OpenBatch[] memory openBatchArr = new IQWManager.OpenBatch[](1);
    openBatchArr[0] = IQWManager.OpenBatch({
        component: address(_QWUniswapV3Stable),
        token: tokenAddress,
        amount: amount,
        asset: address(_uniswapUSDCUSDTPool)
    });

    // Execute the investment
    vm.prank(_owner);
    _qwManager.open(openBatchArr);
    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
    assertEq(usdcBalanceAfter, 0);
  }

  function test_UniswapV3Stable__closeShouldWork() public {
    // Create investment in uniswap
    test_UniswapV3Stable__openShouldWork();

    uint256 ratio = 1e8; // 100%
    uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

    // Create CloseBatch array
    IQWManager.CloseBatch[] memory closeBatchArr = new IQWManager.CloseBatch[](1);
    closeBatchArr[0] = IQWManager.CloseBatch({
        component: address(_QWUniswapV3Stable),
        ratio: ratio,
        asset: address(_uniswapUSDCUSDTPool)
    });

    // Close the position
    vm.prank(_owner);
    _qwManager.close(closeBatchArr);

    uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

    assertGt(usdcBalanceAfter, usdcBalanceBefore);
  }
}
