// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {QWManager} from 'contracts/QWManager.sol';
import {QWRegistry} from 'contracts/QWRegistry.sol';
import {Script} from 'forge-std/Script.sol';

/**
 * @title QwManager Deployment Script
 * @notice This deploys QwManager and QWRegistry contracts
 */
contract DeployQwManager is Script {
  QWManager public qwManager;
  QWRegistry public qwRegistry;

  function run() public {
    vm.startBroadcast();

    // Deploy QwManager and QwRegistry
    qwManager = new QWManager();

    vm.stopBroadcast();
  }
}
