// SPDX-License-Identifier: APACHE
pragma solidity ^0.8.0;

import {IERC20, ILendingPool, IQWComponent, QWAaveV2} from '../../../src/contracts/components/QWAaveV2.sol';
import {Test} from 'forge-std/Test.sol';

contract MockQWAaveV2 is QWAaveV2, Test {
  constructor(
    address _qwManager,
    address _investmentToken,
    address _assetToken,
    address _pool
  ) QWAaveV2(_qwManager, _investmentToken, _assetToken, _pool) {}

  function mock_call_open(uint256 _amount, bool success) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('open(uint256)', _amount),
      abi.encode(success)
    );
  }

  function mock_call_close(uint256 _amount, bool success) public {
    vm.mockCall(address(this), abi.encodeWithSignature('close(uint256)', _amount), abi.encode(success));
  }
}
