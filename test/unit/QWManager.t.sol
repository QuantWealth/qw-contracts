// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20, IQWChild, IQWManager, QWManager} from 'contracts/QWManager.sol';
import {Test} from 'forge-std/Test.sol';
import {MockQWManager} from 'test/smock/MockQWManager.sol';
import {MockQWRegistry} from 'test/smock/MockQWRegistry.sol';

import {SmockHelper} from 'test/smock/SmockHelper.sol';
import {MockQWAave} from 'test/smock/child/MockQWAave.sol';

contract UnitQWManagerTest is Test, SmockHelper {
  MockQWManager public mockQWManager;
  // MockQWRegistry public mockQWRegistry;
  MockQWAave public mockQWAave;
  address[] public targetQWChild;
  address public tokenAddress;
  uint256 public amount;

  function setUp() public {
    mockQWManager = MockQWManager(deployMock('QWManager', type(MockQWManager).creationCode, abi.encode()));
    // mockQWRegistry = new MockQWRegistry(mockQWManager.REGISTRY());
    mockQWAave = new MockQWAave(address(mockQWManager), address(0x456));
    targetQWChild = [address(mockQWAave)];

    tokenAddress = address(0x123);
    amount = 100;
  }

  function test_Execute_Success() public {
    bytes[] memory callData = new bytes[](1);
    // Mock a successful execution
    mockQWManager.mock_call_execute(targetQWChild, callData, tokenAddress, amount);

    // Call the execute function
    mockQWManager.execute(targetQWChild, callData, tokenAddress, amount);
  }

  function test_Close_Success() public {
    bytes[] memory callData = new bytes[](1);
    callData[0] = abi.encode(address(0x123), uint256(100));
    // Mock a successful closing
    mockQWManager.mock_call_close(targetQWChild, callData);

    // Call the close function
    mockQWManager.close(targetQWChild, callData);
  }

  function test_Withdraw_Success() public {
    address user = address(0x789);
    uint256 withdrawAmount = 50;

    // Mock a successful withdrawal
    mockQWManager.mock_call_withdraw(user, withdrawAmount);

    // Call the withdraw function
    mockQWManager.withdraw(user, withdrawAmount);
  }
}
