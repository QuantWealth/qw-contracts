// SPDX-License-Identifier: APACHE
pragma solidity ^0.8.0;

import {IComet, IERC20, IQWChild, QWCompound} from 'contracts/child/QWCompound.sol';
import {Test} from 'forge-std/Test.sol';

contract MockQWCompound is QWCompound, Test {
  constructor(address _qwManager, address _comet) QWCompound(_qwManager, _comet) {}

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
