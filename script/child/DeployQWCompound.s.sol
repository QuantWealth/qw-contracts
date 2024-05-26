// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.23;

import {DeployBase} from '../helpers/DeployBase.sol';

import {QWManager} from 'contracts/QWManager.sol';
import {QWRegistry} from 'contracts/QWRegistry.sol';
import {QWCompound} from 'contracts/child/QWCompound.sol';
import {Script} from 'forge-std/Script.sol';

/**
 * @title QwCompound Deployment Script
 * @notice This deploys QwCompound child contracts
 */
contract DeployQWCompound is Script, DeployBase {
  struct ConfigParams {
    address compoundComet;
  }

  QWCompound public qwCompound;
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
    qwCompound = new QWCompound(baseParams.qwManager, configParams.compoundComet);

    // Register Child in registry
    qwRegistry.registerChild(address(qwCompound));

    vm.stopBroadcast();
  }

  function _readEnvVariables() internal view returns (ConfigParams memory configParams) {
    configParams.compoundComet = vm.envAddress('COMPOUND_COMET_POOL');
    if (configParams.compoundComet == address(0)) revert InvalidAddress();
  }
}
