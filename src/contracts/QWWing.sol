// SPDX-License-Identifier: APACHE
pragma solidity 0.8.14;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract QWWing is AccessControl {

    /// Storage
    // Crispy, slow-cooked, storage records for validated wing agent addresses.
    mapping(address => bool) _wings // alt: flight

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// Errors
    error QWWing__onlyWing_notWing();

    constructor(address operator) {
        // Add global admin role.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Create operator role. Will be able to allow and disable assets.
        _grantRole(OPERATOR_ROLE, operator);
    }

    /// Modifiers
    /**
    * @notice Only accept a valid wing address as msg.sender.
    */
    modifier onlyWing() {
        if ( != msg.sender) revert QWWing__onlyWing_notWing();
        _;
    }
}
