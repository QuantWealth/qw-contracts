// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.23;

import {DeployBase} from '../helpers/DeployBase.sol';

import {QWManager} from 'contracts/QWManager.sol';
import {QWRegistry} from 'contracts/QWRegistry.sol';
import {QWAaveV2} from 'contracts/child/QWAaveV2.sol';
import {Script} from 'forge-std/Script.sol';

/**
 * @title QwAaveV2 Deployment Script
 * @notice This deploys QwAaveV2 child contracts
 */
contract DeployQWAaveV2 is Script, DeployBase {
  struct ConfigParams {
    address aaveLendingPool;
  }

  QWAaveV2 public qwAaveV2;
  QWRegistry public qwRegistry;
  QWManager public qwManager;

  error InvalidAddress(); // Error for invalid registry address

  function run() public {
    vm.startBroadcast();

    // Sanity check deployment parameters.
    DeploymentBaseParams memory baseParams = _readBaseEnvVariables();
    ConfigParams memory configParams = _readEnvVariables();

    qwManager = QWManager(baseParams.qwManager);

    address registryAddr = qwManager.REGISTRY();
    qwRegistry = QWRegistry(registryAddr);

    // Deploy QwChild
    qwAaveV2 = new QWAaveV2(baseParams.qwManager, configParams.aaveLendingPool);

    // Register Child in registry
    qwRegistry.registerChild(address(qwAaveV2));

    vm.stopBroadcast();
  }

  // TODO: make it a shared function that all child contracts can access
  function _readEnvVariables() internal view returns (ConfigParams memory configParams) {
    configParams.aaveLendingPool = vm.envAddress('AAVE_V2_LENDING_POOL');
    if (configParams.aaveLendingPool == address(0)) revert InvalidAddress();
  }
}
