// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IQWManager, QWManager} from 'contracts/QWManager.sol';
import {IQWRegistry} from 'contracts/QWRegistry.sol';
import {Test, console2} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract IntegrationBase is Test {
  uint256 internal constant _FORK_BLOCK = 19_900_000;

  address internal _user = makeAddr('user');
  address internal _owner = makeAddr('owner');
  address internal _usdcWhale = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
  IERC20 internal _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IQWManager internal _qwManager;
  IQWRegistry internal _qwRegistry;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('mainnet'), _FORK_BLOCK);
    vm.prank(_owner);
    _qwManager = new QWManager();
    _qwRegistry = IQWRegistry(_qwManager.REGISTRY());
  }
}
