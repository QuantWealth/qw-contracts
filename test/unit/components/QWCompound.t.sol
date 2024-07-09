// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IComet, IERC20, IQWComponent, QWCompound} from 'contracts/components/QWCompound.sol';
import {Test} from 'forge-std/Test.sol';
import {MockQWCompound} from 'test/smock/components/MockQWCompound.sol';

contract UnitQWAaveV3Test is Test {
  MockQWCompound public mockQWCompund;
  address public qwManager;
  address public comet;
  address public investmentToken;
  address public assetToken;

  function setUp() public {
    qwManager = address(0x123);
    investmentToken = address(0x789);
    assetToken = address(0x777); // TODO: Should the asset token be the comet?
    comet = address(0x456);
    mockQWCompund = new MockQWCompound(qwManager, investmentToken, assetToken, comet);
  }

  function test_open_success() public {
    uint256 amount = 100;

    // Mock a successful call to IPool.supply
    mockQWCompund.mock_call_open(amount, true);

    // Call the create function
    (bool success, uint256 assetAmountReceived) = mockQWCompund.open(amount);

    // TODO: check asset amount received, ensure QWManager received assets

    assertTrue(success, 'Create function should return true on success');
  }

  function test_close_success() public {
    // TODO: Do we need to mint/supply this amount of asset tokens to QWManager first?
    uint256 amount = 100;

    // TODO: Transfer asset tokens to QWCompound.

    // Mock a successful call to IPool.withdraw
    mockQWCompund.mock_call_close(amount, true);

    // Call the close function
    (bool success, uint256 tokenAmountReceived) = mockQWCompund.close(amount);

    // TODO: check asset amount received, ensure QWManager received assets

    assertTrue(success, 'Close function should return true on success');
  }
}
