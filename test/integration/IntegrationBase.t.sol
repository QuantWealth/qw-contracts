// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IQWManager, QWManager} from "contracts/QWManager.sol";
import {IQWRegistry} from "contracts/QWRegistry.sol";
import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract IntegrationBase is Test {
    uint256 internal constant _FORK_BLOCK = 18_920_905;

    address internal _user = makeAddr("user");
    address internal _owner = makeAddr("owner");
    address internal _daiWhale = 0x837c20D568Dfcd35E74E5CC0B8030f9Cebe10A28;
    IERC20 internal _dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IQWManager internal _qwManager;
    IQWRegistry internal _qwRegistry;

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("mainnet"), _FORK_BLOCK);
        vm.prank(_owner);
        _qwManager = new QWManager();
        _qwRegistry = IQWRegistry(_qwManager.REGISTRY());
    }
}
