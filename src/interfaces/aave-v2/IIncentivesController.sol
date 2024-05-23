// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IIncentivesController {
  event AssetConfigUpdated(address indexed asset, uint256 emission);
  event AssetIndexUpdated(address indexed asset, uint256 index);
  event ClaimerSet(address indexed user, address indexed claimer);
  event DistributionEndUpdated(uint256 newDistributionEnd);
  event RewardsAccrued(address indexed user, uint256 amount);
  event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);
  event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);

  function DISTRIBUTION_END() external view returns (uint256);

  function EMISSION_MANAGER() external view returns (address);

  function PRECISION() external view returns (uint8);

  function REVISION() external view returns (uint256);

  function REWARD_TOKEN() external view returns (address);

  function STAKE_TOKEN() external view returns (address);

  function assets(address) external view returns (uint104 emissionPerSecond, uint104 index, uint40 lastUpdateTimestamp);

  function claimRewards(address[] memory assets, uint256 amount, address to) external returns (uint256);

  function claimRewardsOnBehalf(
    address[] memory assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  function claimRewardsToSelf(address[] memory assets, uint256 amount) external returns (uint256);

  function configureAssets(address[] memory assets, uint256[] memory emissionsPerSecond) external;

  function getAssetData(address asset) external view returns (uint256, uint256, uint256);

  function getClaimer(address user) external view returns (address);

  function getDistributionEnd() external view returns (uint256);

  function getRewardsBalance(address[] memory assets, address user) external view returns (uint256);

  function getUserAssetData(address user, address asset) external view returns (uint256);

  function getUserUnclaimedRewards(address _user) external view returns (uint256);

  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;

  function initialize(address) external;

  function setClaimer(address user, address caller) external;

  function setDistributionEnd(uint256 distributionEnd) external;
}
