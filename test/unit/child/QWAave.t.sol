// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20, IPool, IQWChild, QWAave} from 'contracts/child/QWAave.sol';
import {Test} from 'forge-std/Test.sol';
import {MockQWAave} from 'test/smock/child/MockQWAave.sol';

contract QWAaveTest is Test {
  MockQWAave public mockQWAave;
  address public qwManager;
  address public pool;

  function setUp() public {
    qwManager = address(0x123);
    pool = address(0x456);
    mockQWAave = new MockQWAave(qwManager, pool);
  }

  function test_Create_Success() public {
    bytes memory callData = '';
    address tokenAddress = address(0x789);
    uint256 amount = 100;

    // Mock a successful call to IPool.supply
    mockQWAave.mock_call_create(callData, tokenAddress, amount, true);

    // Call the create function
    bool success = mockQWAave.create(callData, tokenAddress, amount);

    assertTrue(success, 'Create function should return true on success');
  }

  function test_Close_Success() public {
    bytes memory callData = abi.encode(address(0x123), uint256(100));

    // Mock a successful call to IPool.withdraw
    mockQWAave.mock_call_close(callData, true);

    // Call the close function
    bool success = mockQWAave.close(callData);

    assertTrue(success, 'Close function should return true on success');
  }
}
