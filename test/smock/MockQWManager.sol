// SPDX-License-Identifier: APACHE
pragma solidity ^0.8.0;

import {IERC20, IQWChild, IQWManager, IQWRegistry, QWManager, QWRegistry} from '../../src/contracts/QWManager.sol';
import {Test} from 'forge-std/Test.sol';

contract MockQWManager is QWManager, Test {
  constructor() QWManager() {}

  function mock_call_execute(
    address[] memory _targetQwChild,
    bytes[] memory _callData,
    address _tokenAddress,
    uint256 _amount
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'execute(address[],bytes[],address,uint256)', _targetQwChild, _callData, _tokenAddress, _amount
      ),
      abi.encode()
    );
  }

  function mock_call_close(address[] memory _targetQwChild, bytes[] memory _callData) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('close(address[],bytes[])', _targetQwChild, _callData), abi.encode()
    );
  }

  function mock_call_withdraw(address user, uint256 amount) public {
    vm.mockCall(address(this), abi.encodeWithSignature('withdraw(address,uint256)', user, amount), abi.encode());
  }
}
