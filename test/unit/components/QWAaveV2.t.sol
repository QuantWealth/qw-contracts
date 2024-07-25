// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';
import {MockQWAaveV2} from 'test/smock/components/MockQWAaveV2.sol';

contract UnitQWAaveV3Test is Test {
  MockQWAaveV2 public mockQWAaveV2;
  address public qwManager;
  address public lendingPool;

  function setUp() public {
    qwManager = address(0x123);
    lendingPool = address(0x456);
    mockQWAaveV2 = new MockQWAaveV2(qwManager, lendingPool);
  }

  function test_open_success() public {
    bytes memory callData = '';
    address tokenAddress = address(0x789);
    uint256 amount = 100;

    // Mock a successful call to IPool.supply
    mockQWAaveV2.mock_call_open(amount, true);

    // Call the create function
    (bool success, uint256 assetAmountReceived) = mockQWAaveV2.open(amount);

    // TODO: check asset amount received, ensure QWManager received assets

    assertTrue(success, 'Create function should return true on success');
  }

  function test_close_success() public {
    uint256 amount = 100;

    // Mock a successful call to IPool.withdraw
    mockQWAaveV2.mock_call_close(amount, true);

    // Call the close function
    (bool success, uint256 tokenAmountReceived) = mockQWAaveV2.close(amount);

    // TODO: Check token amount received, ensure QWManager received it

    assertTrue(success, 'Close function should return true on success');
  }
}
