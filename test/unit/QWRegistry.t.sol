// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';
import {MockQWRegistry} from 'test/smock/MockQWRegistry.sol';
import {SmockHelper} from 'test/smock/SmockHelper.sol';

contract UnitQWRegistryTest is Test, SmockHelper {
  MockQWRegistry mockQWRegistry;
  address constant validQWManager = address(0x123);
  address constant validChildContract = address(0x456);
  address constant invalidChildContract = address(0x789);

  MockQWRegistry mockRegistry;

  function beforeEach() public {
    mockQWRegistry =
      MockQWRegistry(deployMock('QWRegistry', type(MockQWRegistry).creationCode, abi.encode(validQWManager)));
  }

  function testRegisterChild() public {
    mockQWRegistry.mock_call_registerChild(validChildContract);
    // assertTrue(true, 'Child contract should be whitelisted after registration');
    // mockQWRegistry.registerChild(validChildContract);
    // assertTrue(mockQWRegistry.whitelist(validChildContract), 'Child contract should be whitelisted after registration');
  }

    // function testRegisterInvalidChild() public {
  //     mockRegistry.set_whitelist(invalidChildContract, false);
  //     try mockQWRegistry.registerChild(invalidChildContract) {
  //         fail("Registering an invalid child contract should revert");
  //     } catch Error(string memory reason) {
  //         assertEq(reason, "ParentMismatch", "Error message should be 'ParentMismatch'");
  //     } catch (bytes memory) {
  //         fail("Registering an invalid child contract should revert with reason 'ParentMismatch'");
  //     }
  // }
}
