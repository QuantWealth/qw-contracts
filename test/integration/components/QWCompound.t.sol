// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IntegrationBase} from '../IntegrationBase.t.sol';
import {IComet, IERC20, IQWComponent, QWCompound} from 'contracts/components/QWCompound.sol';
import {Test, console2} from 'forge-std/Test.sol';

contract CompoundIntegration is IntegrationBase {
    IComet internal _compoundV3Comet = IComet(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
    IERC20 internal _cUsdcV3 = IERC20(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
    IQWComponent internal _qwCompound;

    function setUp() public virtual override {
        IntegrationBase.setUp();

        _qwCompound = new QWCompound(address(_qwManager), address(_compoundV3Comet), address(_usdc), address(_cUsdcV3));
        vm.prank(_owner);
        _qwRegistry.registerComponent(address(_qwCompound));
    }

    function test_OpenCompound() public {
        uint256 amount = 1e12; // 1 million usdc
        address tokenAddress = address(_usdc);

        uint256 supplyFee = 1; // supply fees taken by compound

        // transfer usdc from user to qwManager contract
        vm.prank(_usdcWhale);
        _usdc.transfer(address(_qwManager), amount);

        uint256 cUsdcV3BalanceBefore = _cUsdcV3.balanceOf(address(_qwManager));
        uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

        // Create an array with one element
        IQWManager.OpenBatch[] memory openBatchArr = new IQWManager.OpenBatch[](1);
        openBatchArr[0] = IQWManager.OpenBatch({
            protocol: address(_qwCompound),
            amount: amount
        });

        // execute the investment
        vm.prank(_owner);
        _qwManager.open(openBatchArr);
        uint256 cUsdcV3BalanceAfter = _cUsdcV3.balanceOf(address(_qwManager));
        uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

        assertGe(cUsdcV3BalanceAfter - cUsdcV3BalanceBefore, amount - supplyFee);
        assertEq(usdcBalanceBefore - usdcBalanceAfter, amount);
        assertEq(usdcBalanceAfter, 0);
    }

    function test_CloseCompound() public {
        // create investment in compound
        test_OpenCompound();

        uint256 ratio = 1e8; // 100% withdrawal
        uint256 withdrawFee = 2; // withdraw fees taken by compound

        uint256 cUsdcV3BalanceBefore = _cUsdcV3.balanceOf(address(_qwManager));
        uint256 usdcBalanceBefore = _usdc.balanceOf(address(_qwManager));

        // Create an array with one element
        IQWManager.CloseBatch[] memory closeBatchArr = new IQWManager.CloseBatch[](1);
        closeBatchArr[0] = IQWManager.CloseBatch({
            protocol: address(_qwCompound),
            ratio: ratio
        });

        // close the position
        vm.prank(_owner);
        _qwManager.close(closeBatchArr);

        uint256 cUsdcV3BalanceAfter = _cUsdcV3.balanceOf(address(_qwManager));
        uint256 usdcBalanceAfter = _usdc.balanceOf(address(_qwManager));

        assertGe(usdcBalanceAfter - usdcBalanceBefore, cUsdcV3BalanceBefore - withdrawFee);
        assertEq(cUsdcV3BalanceAfter, 0);
    }
}
