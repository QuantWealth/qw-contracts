// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IComet, IERC20, IQWChild, QWCompound} from 'contracts/child/QWCompound.sol';
import {Test} from 'forge-std/Test.sol';
import {MockQWCompound} from 'test/smock/child/MockQWCompound.sol';

contract UnitQWAaveTest is Test {
  MockQWCompound public mockQWCompund;
  address public qwManager;
  address public comet;

  function setUp() public {
    qwManager = address(0x123);
    comet = address(0x456);
    mockQWCompund = new MockQWCompound(qwManager, comet);
  }

  function test_Create_Success() public {
    bytes memory callData = '';
    address tokenAddress = address(0x789);
    uint256 amount = 100;

    // Mock a successful call to IPool.supply
    mockQWCompund.mock_call_create(callData, tokenAddress, amount, true);

    // Call the create function
    bool success = mockQWCompund.create(callData, tokenAddress, amount);

    assertTrue(success, 'Create function should return true on success');
  }

  function test_Close_Success() public {
    bytes memory callData = abi.encode(address(0x123), uint256(100));

    // Mock a successful call to IPool.withdraw
    mockQWCompund.mock_call_close(callData, true);

    // Call the close function
    bool success = mockQWCompund.close(callData);

    assertTrue(success, 'Close function should return true on success');
  }
}
