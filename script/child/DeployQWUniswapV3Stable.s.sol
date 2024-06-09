// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.23;

import {DeployBase} from '../helpers/DeployBase.sol';

import {QWManager} from 'contracts/QWManager.sol';
import {QWRegistry} from 'contracts/QWRegistry.sol';
import {QWUniswapV3Stable} from 'contracts/child/QWUniswapV3Stable.sol';
import {Script} from 'forge-std/Script.sol';

/**
 * @title QWUniswapV3Stable Deployment Script
 * @notice This deploys QWUniswapV3Stable child contracts
 */
contract DeployQWUniswapV3Stable is Script, DeployBase {
  struct ConfigParams {
    address nonFungiblePositionManager;
    address uniswapV3StablePool;
    address uniswapFactory;
    address weth9;
  }

  QWUniswapV3Stable public qWUniswapV3Stable;
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
    qWUniswapV3Stable = new QWUniswapV3Stable(baseParams.qwManager, configParams.nonFungiblePositionManager, configParams.uniswapFactory, configParams.weth9, configParams.uniswapV3StablePool);

    // Register Child in registry
    qwRegistry.registerChild(address(qWUniswapV3Stable));

    vm.stopBroadcast();
  }

  function _readEnvVariables() internal view returns (ConfigParams memory configParams) {
    configParams.nonFungiblePositionManager = vm.envAddress('NON_FUNGIBLE_POSITION_MANAGER');
    if (configParams.nonFungiblePositionManager == address(0)) revert InvalidAddress();

    configParams.uniswapV3StablePool = vm.envAddress('UNISWAP_STABLE_V3_POOL');
    if (configParams.uniswapV3StablePool == address(0)) revert InvalidAddress();

    configParams.uniswapFactory = vm.envAddress('UNISWAP_FACTORY');
    if (configParams.uniswapFactory == address(0)) revert InvalidAddress();

    configParams.weth9 = vm.envAddress('WETH9');
    if (configParams.weth9 == address(0)) revert InvalidAddress();
  }
}
