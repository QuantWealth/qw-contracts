// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20, IPool, IQWComponent, QWAaveV3} from 'contracts/components/QWAaveV3.sol';
import {Test} from 'forge-std/Test.sol';
import {MockQWAaveV3} from 'test/smock/components/MockQWAaveV3.sol';

contract UnitQWAaveV3Test is Test {
  MockQWAaveV3 public mockQWAaveV3;
  address public qwManager;
  address public pool;

  function setUp() public {
    qwManager = address(0x123);
    pool = address(0x456);
    mockQWAaveV3 = new MockQWAaveV3(qwManager, pool);
  }

  function test_open_success() public {
    address tokenAddress = address(0x789);
    uint256 amount = 100;

    // Mock a successful call to IPool.supply
    mockQWAaveV3.mock_call_open(amount, true);

    // Call the open function
    (bool success, uint256 assetAmountReceived) = mockQWAaveV3.open(amount);

    // TODO: check asset amount received, ensure QWManager received assets

    assertTrue(success, 'Create function should return true on success');
  }

  function test_close_success() public {
    uint256 amount = 100;

    // Mock a successful call to IPool.withdraw
    mockQWAaveV3.mock_call_close(amount, true);

    // Call the close function
    (bool success, uint256 tokenAmountReceived) = mockQWAaveV3.close(amount);

    // TODO: Check token amount received, ensure QWManager received it

    assertTrue(success, 'Close function should return true on success');
  }
}
