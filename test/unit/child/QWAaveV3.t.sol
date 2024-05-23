// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20, IPool, IQWChild, QWAaveV3} from 'contracts/child/QWAaveV3.sol';
import {Test} from 'forge-std/Test.sol';
import {MockQWAaveV3} from 'test/smock/child/MockQWAaveV3.sol';

contract UnitQWAaveV3Test is Test {
  MockQWAaveV3 public mockQWAaveV3;
  address public qwManager;
  address public pool;

  function setUp() public {
    qwManager = address(0x123);
    pool = address(0x456);
    mockQWAaveV3 = new MockQWAaveV3(qwManager, pool);
  }

  function test_Create_Success() public {
    bytes memory callData = '';
    address tokenAddress = address(0x789);
    uint256 amount = 100;

    // Mock a successful call to IPool.supply
    mockQWAaveV3.mock_call_create(callData, tokenAddress, amount, true);

    // Call the create function
    bool success = mockQWAaveV3.create(callData, tokenAddress, amount);

    assertTrue(success, 'Create function should return true on success');
  }

  function test_Close_Success() public {
    bytes memory callData = abi.encode(address(0x123), uint256(100));

    // Mock a successful call to IPool.withdraw
    mockQWAaveV3.mock_call_close(callData, true);

    // Call the close function
    bool success = mockQWAaveV3.close(callData);

    assertTrue(success, 'Close function should return true on success');
  }
}
