// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20, IPool, IQWChild, QWAave} from "contracts/child/QWAave.sol";
import {IntegrationBase} from "../IntegrationBase.t.sol";

contract AaveIntegration is IntegrationBase {
    IPool internal _aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IERC20 internal _aDai = IERC20(0x018008bfb33d285247A21d44E50697654f754e63);
    IQWChild internal _qwAave;

    function setUp() public virtual override {
        IntegrationBase.setUp();

        _qwAave = new QWAave(address(_qwManager), address(_aavePool));
        _qwRegistry.registerChild(address(_qwAave));
    }

    function test_Create_Aave() public {
        vm.startPrank(_daiWhale);
        uint256 amount = 1_000_000 ether;
        bytes memory callData = '';
        address tokenAddress = address(_dai);

        // transfer dai from user to qwManager contract
        _dai.transfer(address(_qwManager), amount);

        uint256 aDaiBalanceBefore = _aDai.balanceOf(address(_qwManager));
        uint256 daiBalanceBefore = _dai.balanceOf(address(_qwManager));
        
        // Create dynamic arrays with one element each
        address[] memory targetQWChild = new address[](1);
        targetQWChild[0] = address(_qwAave);
        
        bytes[] memory callDataArr = new bytes[](1);
        callDataArr[0] = callData;
        
        // execute the investment
        _qwManager.execute(targetQWChild, callDataArr, tokenAddress, amount);
        uint256 aDaiBalanceAfter = _aDai.balanceOf(address(_qwManager));
        uint256 daiBalanceAfter = _dai.balanceOf(address(_qwManager));

        assertGe(aDaiBalanceAfter - aDaiBalanceBefore, amount);
        assertEq(daiBalanceBefore - daiBalanceAfter, amount);
        assertEq(daiBalanceAfter, 0);
        vm.stopPrank();
    }

    function test_Close_Aave() public {
        // create investment in aave
        test_Create_Aave();

        vm.startPrank(_daiWhale);
        uint256 amount = 1_000_000 ether;
        bytes memory callData = abi.encode(_dai, amount);
        
        // Create dynamic arrays with one element each
        address[] memory targetQWChild = new address[](1);
        targetQWChild[0] = address(_qwAave);
        
        bytes[] memory callDataArr = new bytes[](1);
        callDataArr[0] = callData;
        
        // bug: qwAave contract need to have aDai tokens and approve them to aave pool contract to withdraw
        _qwManager.close(targetQWChild, callDataArr);
        vm.stopPrank();
    }
}
