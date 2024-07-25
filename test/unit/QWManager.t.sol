// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20, IQWComponent, IQWManager, QWManager} from 'contracts/QWManager.sol';
import {Test} from 'forge-std/Test.sol';
import {MockQWManager} from 'test/smock/MockQWManager.sol';
import {MockQWRegistry} from 'test/smock/MockQWRegistry.sol';
import {SmockHelper} from 'test/smock/SmockHelper.sol';
import {MockQWAaveV3} from 'test/smock/components/MockQWAaveV3.sol';

contract UnitQWManagerTest is Test, SmockHelper {
  MockQWManager public mockQWManager;
  MockQWAaveV3 public mockQWAaveV3;
  MockQWRegistry public mockQWRegistry;
  address public investmentToken;
  address public assetToken;
  uint256 public amount;

  function setUp() public {
    investmentToken = address(0x123);
    assetToken = address(0x456);
    amount = 100;

    mockQWRegistry = new MockQWRegistry();
    mockQWManager = MockQWManager(deployMock('QWManager', type(MockQWManager).creationCode, abi.encode(address(mockQWRegistry))));
    mockQWAaveV3 = new MockQWAaveV3(address(mockQWManager), investmentToken, assetToken, address(0x789));

    // Whitelist the mock protocol
    mockQWRegistry.whitelist(address(mockQWAaveV3));
  }

  function test_open_success() public {
    IQWManager.OpenBatch[] memory batches = new IQWManager.OpenBatch[](1);
    batches[0] = IQWManager.OpenBatch({
        protocol: address(mockQWAaveV3),
        amount: amount
    });

    // Mock a successful open call
    mockQWManager.mock_call_open(batches);

    // Call the open function
    mockQWManager.open(batches);
  }

  function test_open_fail_NotWhitelisted() public {
    IQWManager.OpenBatch[] memory batches = new IQWManager.OpenBatch[](1);
    batches[0] = IQWManager.OpenBatch({
        protocol: address(0x111), // not whitelisted
        amount: amount
    });

    // Expect revert due to contract not whitelisted
    vm.expectRevert('ContractNotWhitelisted');
    mockQWManager.open(batches);
  }

  function test_open_fail_CallFailed() public {
    IQWManager.OpenBatch[] memory batches = new IQWManager.OpenBatch[](1);
    batches[0] = IQWManager.OpenBatch({
        protocol: address(mockQWAaveV3),
        amount: amount
    });

    // Mock a failed open call
    mockQWManager.mock_call_open_fails(batches);

    // Expect revert due to call failed
    vm.expectRevert('CallFailed');
    mockQWManager.open(batches);
  }

  function test_close_success() public {
    IQWManager.CloseBatch[] memory batches = new IQWManager.CloseBatch[](1);
    batches[0] = IQWManager.CloseBatch({
        protocol: address(mockQWAaveV3),
        ratio: 50000000 // 50% with 8 decimal places
    });

    // Mock a successful close call
    mockQWManager.mock_call_close(batches);

    // Call the close function
    mockQWManager.close(batches);
  }

  function test_close_fail_CallFailed() public {
    IQWManager.CloseBatch[] memory batches = new IQWManager.CloseBatch[](1);
    batches[0] = IQWManager.CloseBatch({
        protocol: address(mockQWAaveV3),
        ratio: 50000000 // 50% with 8 decimal places
    });

    // Mock a failed close call
    mockQWManager.mock_call_close_fails(batches);

    // Expect revert due to call failed
    vm.expectRevert('CallFailed');
    mockQWManager.close(batches);
  }

  function test_withdraw_success() public {
    address user = address(0x789);
    uint256 withdrawAmount = 50;

    // Mock a successful withdrawal
    mockQWManager.mock_call_withdraw(user, investmentToken, withdrawAmount);

    // Call the withdraw function
    mockQWManager.withdraw(user, investmentToken, withdrawAmount);
  }

  function test_withdraw_fail_TransferFailed() public {
    address user = address(0x789);
    uint256 withdrawAmount = 50;

    // Mock a failed withdrawal
    mockQWManager.mock_call_withdraw_fails(user, investmentToken, withdrawAmount);

    // Expect revert due to transfer failed
    vm.expectRevert('TransferFailed');
    mockQWManager.withdraw(user, investmentToken, withdrawAmount);
  }

  function test_receiveFunds_success() public {
    address user = address(0x789);
    uint256 receiveAmount = 50;

    // Mock a successful receive funds
    mockQWManager.mock_call_receiveFunds(user, investmentToken, receiveAmount);

    // Call the receiveFunds function
    mockQWManager.receiveFunds(user, investmentToken, receiveAmount);
  }

  function test_receiveFunds_fail_TransferFromFailed() public {
    address user = address(0x789);
    uint256 receiveAmount = 50;

    // Mock a failed receive funds
    mockQWManager.mock_call_receiveFunds_fails(user, investmentToken, receiveAmount);

    // Expect revert due to transferFrom failed
    vm.expectRevert('TransferFromFailed');
    mockQWManager.receiveFunds(user, investmentToken, receiveAmount);
  }
}
