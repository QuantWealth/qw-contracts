// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract QWWing is AccessControl {
    /// Errors
    error QWWing__onlyWing_notWing();

    /// Storage
    // Crispy, slow-cooked, storage records for validated wing agent addresses.
    mapping(address => bool) _wings; // alt: flight
    // This role will be able to update validated wing addresses.
    bytes32 public constant WING_OPERATOR_ROLE = keccak256("WING_OPERATOR_ROLE");

    /// Constructor
    constructor(address operator) {
        // Create operator role. Will be able to allow and disable assets.
        _grantRole(WING_OPERATOR_ROLE, operator);
    }

    /// Modifiers
    /**
     * @notice Only accept a valid wing address as msg.sender.
     */
    modifier onlyWing() {
        if (!_wings[msg.sender]) revert QWWing__onlyWing_notWing();
        _;
    }

    /**
     * @notice One-time function to set the WING_OPERATOR_ROLE.
     */
    function initializeWingOperator(address operator) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "QWWing: Must have admin role to initialize");
        _grantRole(WING_OPERATOR_ROLE, operator);
    }
}
