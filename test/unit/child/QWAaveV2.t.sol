// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';
import {MockQWAaveV2} from 'test/smock/child/MockQWAaveV2.sol';

contract UnitQWAaveV3Test is Test {
  MockQWAaveV2 public mockQWAaveV2;
  address public qwManager;
  address public lendingPool;

  function setUp() public {
    qwManager = address(0x123);
    lendingPool = address(0x456);
    mockQWAaveV2 = new MockQWAaveV2(qwManager, lendingPool);
  }

  function test_Create_Success() public {
    bytes memory callData = '';
    address tokenAddress = address(0x789);
    uint256 amount = 100;

    // Mock a successful call to IPool.supply
    mockQWAaveV2.mock_call_create(callData, tokenAddress, amount, true);

    // Call the create function
    bool success = mockQWAaveV2.create(callData, tokenAddress, amount);

    assertTrue(success, 'Create function should return true on success');
  }

  function test_Close_Success() public {
    bytes memory callData = abi.encode(address(0x123), uint256(100));

    // Mock a successful call to IPool.withdraw
    mockQWAaveV2.mock_call_close(callData, true);

    // Call the close function
    bool success = mockQWAaveV2.close(callData);

    assertTrue(success, 'Close function should return true on success');
  }
}
