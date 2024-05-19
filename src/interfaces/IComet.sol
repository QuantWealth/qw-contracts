// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

interface IComet {
  error Absurd();
  error AlreadyInitialized();
  error BadAsset();
  error BadDecimals();
  error BadDiscount();
  error BadMinimum();
  error BadPrice();
  error BorrowTooSmall();
  error BorrowCFTooLarge();
  error InsufficientReserves();
  error LiquidateCFTooLarge();
  error NoSelfTransfer();
  error NotCollateralized();
  error NotForSale();
  error NotLiquidatable();
  error Paused();
  error SupplyCapExceeded();
  error TimestampTooLarge();
  error TooManyAssets();
  error TooMuchSlippage();
  error TransferInFailed();
  error TransferOutFailed();
  error Unauthorized();
  error BadAmount();
  error BadNonce();
  error BadSignatory();
  error InvalidValueS();
  error InvalidValueV();
  error SignatureExpired();

  struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
  }

  event Supply(address indexed from, address indexed dst, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Withdraw(address indexed src, address indexed to, uint256 amount);

  event SupplyCollateral(address indexed from, address indexed dst, address indexed asset, uint256 amount);
  event TransferCollateral(address indexed from, address indexed to, address indexed asset, uint256 amount);
  event WithdrawCollateral(address indexed src, address indexed to, address indexed asset, uint256 amount);

  /// @notice Event emitted when a borrow position is absorbed by the protocol
  event AbsorbDebt(address indexed absorber, address indexed borrower, uint256 basePaidOut, uint256 usdValue);

  /// @notice Event emitted when a user's collateral is absorbed by the protocol
  event AbsorbCollateral(
    address indexed absorber,
    address indexed borrower,
    address indexed asset,
    uint256 collateralAbsorbed,
    uint256 usdValue
  );

  /// @notice Event emitted when a collateral asset is purchased from the protocol
  event BuyCollateral(address indexed buyer, address indexed asset, uint256 baseAmount, uint256 collateralAmount);

  /// @notice Event emitted when an action is paused/unpaused
  event PauseAction(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused);

  /// @notice Event emitted when reserves are withdrawn by the governor
  event WithdrawReserves(address indexed to, uint256 amount);

  function supply(address asset, uint256 amount) external;
  function supplyTo(address dst, address asset, uint256 amount) external;
  function supplyFrom(address from, address dst, address asset, uint256 amount) external;

  function transfer(address dst, uint256 amount) external returns (bool);
  function transferFrom(address src, address dst, uint256 amount) external returns (bool);

  function transferAsset(address dst, address asset, uint256 amount) external;
  function transferAssetFrom(address src, address dst, address asset, uint256 amount) external;

  function withdraw(address asset, uint256 amount) external;
  function withdrawTo(address to, address asset, uint256 amount) external;
  function withdrawFrom(address src, address to, address asset, uint256 amount) external;

  function approveThis(address manager, address asset, uint256 amount) external;
  function withdrawReserves(address to, uint256 amount) external;

  function absorb(address absorber, address[] calldata accounts) external;
  function buyCollateral(address asset, uint256 minAmount, uint256 baseAmount, address recipient) external;
  function quoteCollateral(address asset, uint256 baseAmount) external view returns (uint256);

  function getAssetInfo(uint8 i) external view returns (AssetInfo memory);
  function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);
  function getReserves() external view returns (int256);
  function getPrice(address priceFeed) external view returns (uint256);

  function isBorrowCollateralized(address account) external view returns (bool);
  function isLiquidatable(address account) external view returns (bool);

  function totalSupply() external view returns (uint256);
  function totalBorrow() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function borrowBalanceOf(address account) external view returns (uint256);

  function pause(
    bool supplyPaused,
    bool transferPaused,
    bool withdrawPaused,
    bool absorbPaused,
    bool buyPaused
  ) external;
  function isSupplyPaused() external view returns (bool);
  function isTransferPaused() external view returns (bool);
  function isWithdrawPaused() external view returns (bool);
  function isAbsorbPaused() external view returns (bool);
  function isBuyPaused() external view returns (bool);

  function accrueAccount(address account) external;
  function getSupplyRate(uint256 utilization) external view returns (uint64);
  function getBorrowRate(uint256 utilization) external view returns (uint64);
  function getUtilization() external view returns (uint256);

  function governor() external view returns (address);
  function pauseGuardian() external view returns (address);
  function baseToken() external view returns (address);
  function baseTokenPriceFeed() external view returns (address);
  function extensionDelegate() external view returns (address);

  /// @dev uint64
  function supplyKink() external view returns (uint256);
  /// @dev uint64
  function supplyPerSecondInterestRateSlopeLow() external view returns (uint256);
  /// @dev uint64
  function supplyPerSecondInterestRateSlopeHigh() external view returns (uint256);
  /// @dev uint64
  function supplyPerSecondInterestRateBase() external view returns (uint256);
  /// @dev uint64
  function borrowKink() external view returns (uint256);
  /// @dev uint64
  function borrowPerSecondInterestRateSlopeLow() external view returns (uint256);
  /// @dev uint64
  function borrowPerSecondInterestRateSlopeHigh() external view returns (uint256);
  /// @dev uint64
  function borrowPerSecondInterestRateBase() external view returns (uint256);
  /// @dev uint64
  function storeFrontPriceFactor() external view returns (uint256);

  /// @dev uint64
  function baseScale() external view returns (uint256);
  /// @dev uint64
  function trackingIndexScale() external view returns (uint256);

  /// @dev uint64
  function baseTrackingSupplySpeed() external view returns (uint256);
  /// @dev uint64
  function baseTrackingBorrowSpeed() external view returns (uint256);
  /// @dev uint104
  function baseMinForRewards() external view returns (uint256);
  /// @dev uint104
  function baseBorrowMin() external view returns (uint256);
  /// @dev uint104
  function targetReserves() external view returns (uint256);

  function numAssets() external view returns (uint8);
  function decimals() external view returns (uint8);

  function initializeStorage() external;

  function collateralBalanceOf(address account, address asset) external view returns (uint128);
  function allow(address manager, bool isAllowed_) external;
}
