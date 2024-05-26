// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {Script} from 'forge-std/Script.sol';

contract DeployBase is Script {
  struct DeploymentBaseParams {
    address qwManager;
  }

  // Custom errors
  error InvalidManagerAddress(); // Error for invalid manager address

  // Read env variables and do sanity checks
  function _readBaseEnvVariables() internal view returns (DeploymentBaseParams memory baseParams) {
    baseParams.qwManager = vm.envAddress('QW_MANAGER');
    if (baseParams.qwManager == address(0)) revert InvalidManagerAddress();
  }
}
