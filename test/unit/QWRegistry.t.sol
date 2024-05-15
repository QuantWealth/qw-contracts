// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {MockQWManager} from "test/smock/MockQWManager.sol";
import {MockQWRegistry} from "test/smock/MockQWRegistry.sol";

import {SmockHelper} from "test/smock/SmockHelper.sol";
import {MockQWAave} from "test/smock/child/MockQWAave.sol";

contract UnitQWRegistryTest is Test, SmockHelper {
    MockQWRegistry public mockQWRegistry;
    MockQWManager public mockQWManager;
    MockQWAave public mockQWAave;

    function beforeEach() public {
        mockQWManager = MockQWManager(
            deployMock(
                "QWManager",
                type(MockQWManager).creationCode,
                abi.encode()
            )
        );
        mockQWAave = MockQWAave(
            deployMock(
                "QWAave",
                type(MockQWAave).creationCode,
                abi.encode(address(mockQWManager), address(0x456))
            )
        );

        address validQWManager = address(mockQWManager);
        mockQWRegistry = MockQWRegistry(
            deployMock(
                "QWRegistry",
                type(MockQWRegistry).creationCode,
                abi.encode(validQWManager)
            )
        );
    }

    function testRegisterChild() public {
        vm.skip(true);

        address validChildContract = address(mockQWAave);
        // Record logs to capture emitted events
        vm.recordLogs();

        // Call registerChild function on the mock contract
        // mockQWRegistry.registerChild(validChildContract);

        // Assert that the child contract is whitelisted after registration
        assertTrue(
            mockQWRegistry.whitelist(validChildContract),
            "Child contract should be whitelisted after registration"
        );

        // Retrieve the recorded logs
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Add assertions based on the logs if needed
        // For example, you can check if the ChildRegistered event was emitted
        // assert(logs.length == 1, "Expected one log entry");
        // assert(logs[0].event == "ChildRegistered", "Expected ChildRegistered event");

        // You can also use debug statements to print information
        for (uint256 i = 0; i < logs.length; i++) {
            emit log_named_uint("Log index: ", i);
            // emit log_named_address("Address: ", logs[i].address);
            emit log_named_bytes32("Topics: ", logs[i].topics[0]);
        }
    }
}
