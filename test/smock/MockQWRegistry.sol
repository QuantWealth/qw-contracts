// SPDX-License-Identifier: APACHE
pragma solidity ^0.8.0;

import {IQWChild, IQWRegistry, QWRegistry} from "../../src/contracts/QWRegistry.sol";
import {Test} from "forge-std/Test.sol";

contract MockQWRegistry is QWRegistry, Test {
    function set_whitelist(address _key0, bool _value) public {
        whitelist[_key0] = _value;
    }

    function mock_call_whitelist(address _key0, bool _value) public {
        vm.mockCall(
            address(this),
            abi.encodeWithSignature("whitelist(address)", _key0),
            abi.encode(_value)
        );
    }

    constructor(address _qwManager) QWRegistry(_qwManager) {}

    function mock_call_registerChild(address _child) public {
        // vm.mockCall(address(this), abi.encodeWithSignature('registerChild(address)', _child), abi.encode());
    }
}
