// SPDX-License-Identifier: APACHE
pragma solidity ^0.8.0;

import {IERC20, IPool, IQWChild, QWAave} from '../../../src/contracts/child/QWAave.sol';
import {Test} from 'forge-std/Test.sol';

contract MockQWAave is QWAave, Test {
  constructor(address _qwManager, address _pool) QWAave(_qwManager, _pool) {}

  function mock_call_create(bytes memory _callData, address _tokenAddress, uint256 _amount, bool success) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('create(bytes,address,uint256)', _callData, _tokenAddress, _amount),
      abi.encode(success)
    );
  }

  function mock_call_close(bytes memory _callData, bool success) public {
    vm.mockCall(address(this), abi.encodeWithSignature('close(bytes)', _callData), abi.encode(success));
  }
}
