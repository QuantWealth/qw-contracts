// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

contract QWShares {
    // Mapping to store user shares for each protocol
    mapping(address => mapping(address => uint256)) public shares;
    // Mapping to store total shares for each protocol
    mapping(address => uint256) public totalShares;

    // Function to update shares on deposit
    function _updateSharesOnDeposit(address _user, uint256 _shares, address _protocol) internal {
        shares[_protocol][_user] += _shares;
        totalShares[_protocol] += _shares;
    }

    // Function to update shares on withdrawal
    function _updateSharesOnWithdrawal(address _user, uint256 _shares, address _protocol) internal {
        shares[_protocol][_user] -= _shares;
        totalShares[_protocol] -= _shares;
    }
}
