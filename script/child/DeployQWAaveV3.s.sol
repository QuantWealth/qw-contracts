// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.23;

import {DeployBase} from '../helpers/DeployBase.sol';
import {QWRegistry} from 'contracts/QWRegistry.sol';
import {QWAaveV3} from 'contracts/child/QWAaveV3.sol';
import {Script} from 'forge-std/Script.sol';

contract DeployQWAaveV3 is Script, DeployBase {
  struct ConfigParams {
    address aavePool;
  }

  QWAaveV3 public qwAaveV3;
  QWRegistry public qwRegistry;

  error InvalidAddress(); // Error for invalid registry address

  function run() public {
    vm.startBroadcast();

    // Sanity check deployment parameters.
    DeploymentBaseParams memory baseParams = _readBaseEnvVariables();
    ConfigParams memory configParams = _readEnvVariables();

    qwRegistry = QWRegistry(baseParams.qwRegistry);

    // Deploy QwChild
    qwAaveV3 = new QWAaveV3(baseParams.qwManager, configParams.aavePool);

    // Register Child in registry
    qwRegistry.registerChild(address(qwAaveV3));

    vm.stopBroadcast();
  }

  function _readEnvVariables() internal view returns (ConfigParams memory configParams) {
    // Chain ID.
    configParams.aavePool = vm.envAddress('AAVE_V3_POOL');
    if (configParams.aavePool == address(0)) revert InvalidAddress();
  }
}
