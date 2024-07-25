// SPDX-License-Identifier: APACHE
pragma solidity ^0.8.0;

import {IComet, IERC20, IQWComponent, QWCompound} from '../../../src/contracts/components/QWCompound.sol';
import {Test} from 'forge-std/Test.sol';

contract MockQWCompound is QWCompound, Test {
  constructor(
    address _qwManager,
    address _investmentToken,
    address _assetToken,
    address _comet
  ) QWCompound(_qwManager, _investmentToken, _assetToken, _comet) {}

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
