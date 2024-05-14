// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

// import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

///
/// NOT PART OF FIRST MVP
///

// abstract contract QWGuardian is AccessControl {
//     /// Errors
//     error QWGuardian__onlyGuardian_notGuardian();

//     /// Storage
//     // Storage records for validated guardian agent addresses.
//     mapping(address => bool) _guardians;
//     // This role will be able to update validated guardian addresses.
//     bytes32 public constant GUARDIAN_OPERATOR_ROLE =
//         keccak256("GUARDIAN_OPERATOR_ROLE");

//     constructor(address operator) {
//         // Create operator role. Will be able to allow and disable assets.
//         _grantRole(GUARDIAN_OPERATOR_ROLE, operator);
//     }

//     /// Modifiers
//     /**
//      * @notice Only accept a valid guardian address as msg.sender.
//      */
//     modifier onlyGuardian() {
//         if (!_guardians[msg.sender])
//             revert QWGuardian__onlyGuardian_notGuardian();
//         _;
//     }

//     /**
//      * @notice One-time function to set the GUARDIAN_OPERATOR_ROLE.
//      */
//     function initializeGuardianOperator(address operator) external {
//         require(
//             hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
//             "QWGuardian: Must have admin role to initialize"
//         );
//         _grantRole(GUARDIAN_OPERATOR_ROLE, operator);
//     }
// }
