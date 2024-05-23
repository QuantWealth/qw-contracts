// SPDX-License-Identifier: APACHE
pragma solidity ^0.8.0;

import {QWAaveV2} from '../../../src/contracts/child/QWAaveV2.sol';
import {Test} from 'forge-std/Test.sol';

contract MockQWAaveV2 is QWAaveV2, Test {
  constructor(address _qwManager, address _lendingPool) QWAaveV2(_qwManager, _lendingPool) {}

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
