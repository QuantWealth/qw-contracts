// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {QWWing} from "./QWWing.sol";
import {QWGuardian} from "./QWGuardian.sol";

/**
 * @title Quant Wealth Manager Contract
 * @notice This contract manages the execution, closing, and withdrawal of various strategies for Quant Wealth.
 * It inherits access control functionality from QWWing and QWGuardian for role-based access.
 */
contract QWManager is IQWManager, QWWing, QWGuardian {
    /// Errors
    error QWManager__onlyAdmin_notAdmin();

    /// Storage


    /// Constructor
    /**
     * @dev Constructor that sets up the default admin role and initializes the QWWing and QWGuardian contracts with the operator address.
     * @param operator The address that will be granted the WING_OPERATOR_ROLE and GUARDIAN_OPERATOR_ROLE.
     */
    constructor(address operator) QWWing(operator) QWGuardian(operator) {
        // Add global admin role.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// Modifiers
    /**
     * @dev Modifier to check if the caller has the DEFAULT_ADMIN_ROLE.
     */
    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert QWManager__onlyAdmin_notAdmin();
        _;
    }

    /// External Functions
    /**
     * @notice Initialize the Wing Operator role.
     * @dev This function can only be called by an address with the DEFAULT_ADMIN_ROLE.
     * @param operator The address to be granted the WING_OPERATOR_ROLE.
     */
    function initializeWingOperator(address operator) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "QWManager: Must have admin role to initialize");
        _grantRole(WING_OPERATOR_ROLE, operator);
    }

    /**
     * @notice Initialize the Guardian Operator role.
     * @dev This function can only be called by an address with the DEFAULT_ADMIN_ROLE.
     * @param operator The address to be granted the GUARDIAN_OPERATOR_ROLE.
     */
    function initializeGuardianOperator(address operator) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "QWManager: Must have admin role to initialize");
        _grantRole(GUARDIAN_OPERATOR_ROLE, operator);
    }

    /**
     * @notice Execute a series of transactions.
     * @dev This function can only be called by an address with the WING_OPERATOR_ROLE.
     * Transfers specified amounts of tokens and calls target contracts with provided calldata.
     * @param _targetQwi List of contract addresses to interact with.
     * @param _callData Encoded function calls to be executed on the target contracts.
     * @param _tokenAddress List of token addresses to transfer.
     * @param _amount List of amounts corresponding to each token to be transferred.
     */
    function execute(
        address[] memory _targetQwi,
        bytes[] memory _callData,
        address[] memory _tokenAddress,
        uint256[] memory _amount
    ) external override onlyWing {
        require(_targetQwi.length == _callData.length, "QWManager: Mismatched input lengths");
        require(_tokenAddress.length == _amount.length, "QWManager: Mismatched token inputs");

        for (uint256 i = 0; i < _targetQwi.length; i++) {
            for (uint256 j = 0; j < _tokenAddress.length; j++) {
                IERC20(_tokenAddress[j]).transferFrom(msg.sender, address(this), _amount[j]);
            }
            (bool success, ) = _targetQwi[i].call(_callData[i]);
            require(success, "QWManager: Call failed");
        }
    }

    /**
     * @notice Close a series of transactions.
     * @dev This function can only be called by an address with the GUARDIAN_OPERATOR_ROLE.
     * Calls target contracts with provided calldata to close positions.
     * @param _targetQwi List of contract addresses to interact with.
     * @param _callData Encoded function calls to be executed on the target contracts.
     */
    function close(
        address[] memory _targetQwi,
        bytes[] memory _callData
    ) external override onlyGuardian {
        require(_targetQwi.length == _callData.length, "QWManager: Mismatched input lengths");

        for (uint256 i = 0; i < _targetQwi.length; i++) {
            (bool success, ) = _targetQwi[i].call(_callData[i]);
            require(success, "QWManager: Call failed");
        }
    }

    /**
     * @notice Withdraw funds to a specified user.
     * @dev This function can only be called by an address with the GUARDIAN_OPERATOR_ROLE.
     * Transfers a specified amount of funds to the user.
     * @param user The address of the user to receive the funds.
     * @param amount The amount of funds to transfer to the user.
     */
    function withdraw(
        address user,
        uint256 amount
    ) external override onlyGuardian {
        payable(user).transfer(amount);
    }
}
