// SPDX-License-Identifier: APACHE
pragma solidity 0.8.23;

import {QWRegistry} from './QWRegistry.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IQWComponent} from 'interfaces/IQWComponent.sol';
import {IQWManager} from 'interfaces/IQWManager.sol';
import {IQWRegistry} from 'interfaces/IQWRegistry.sol';

/**
 * @title Quant Wealth Manager Contract
 * @notice This contract manages the execution, closing, and withdrawal of various strategies for Quant Wealth.
 */
contract QWManager is IQWManager, Ownable {
    enum ProtocolClassification { NONE, POSITION_MANAGER }

    struct Protocol {
        ProtocolClassification classification;
        address assetAddress;
        uint256 assetAmount;
        address investmentToken;
        uint256 nftId;
    }

    // Variables
    address public immutable REGISTRY;

    // Tracks protocol assets and other information.
    mapping(address => Protocol) public protocols;

    event ProtocolDeposit(
        uint256 indexed epoch,
        address indexed protocol,
        uint256 amount,
        uint256 previousTotalHoldings,
        uint256 newTotalHoldings
    );
    event ProtocolWithdrawal(
        uint256 indexed epoch,
        address indexed protocol,
        uint256 ratio,
        uint256 tokenAmountReceived
    );

    // Custom errors
    error InvalidInputLength(); // Error for mismatched input lengths
    error ContractNotWhitelisted(); // Error for contract not whitelisted
    error CallFailed(); // Error for call failed

    // Constructor
    constructor() Ownable(msg.sender) {
        // Deploy the QWRegistry contract and set the REGISTRY address
        QWRegistry _registry = new QWRegistry(address(this), msg.sender);
        REGISTRY = address(_registry);
    }

    // External Functions

    /**
     * @notice Execute a series of investments in batches for multiple protocols.
     * Transfers specified amounts of tokens and calls target contracts with provided calldata.
     * @param batches Array of ExecuteBatch data containing protocol, users, contributions, token, and amount.
     */
    function open(OpenBatch[] memory batches) external onlyOwner {
        for (uint256 i = 0; i < batches.length; i++) {
            OpenBatch memory batch = batches[i];

            // Check if the target contract is whitelisted
            if (!IQWRegistry(REGISTRY).whitelist(batch.protocol)) {
                revert ContractNotWhitelisted();
            }

            // Get the protocol asset details.
            Protocol memory protocol = protocols[batch.protocol];
            uint256 previousAmount = protocol.assetAmount;

            // Approve the target contract to spend the specified amount of tokens.
            IERC20 token = IERC20(protocol.investmentToken);
            token.approve(address(batch.protocol), batch.amount);

            // Transfer relevant NFT position manager, if applicable.
            if (protocol.classification == ProtocolClassification.POSITION_MANAGER) {
                IERC721 nft = IERC721(protocol.assetAddress);
                nft.transferFrom(address(this), batch.protocol, protocol.nftId);
            }

            // Call the open function on the target contract with the provided calldata.
            (bool success, uint256 assetAmountReceived) = IQWComponent(batch.protocol).open(batch.amount);
            if (!success) {
                // TODO: Event for batches that fail.
                revert CallFailed();
            }
            // TODO: Ensure protocol asset correct amount was transferred.

            // Update the protocol with a new asset amount for the asset we have purchased.
            protocol.assetAmount = previousAmount + assetAmountReceived;
            protocols[batch.protocol] = protocol;

            // Emit deposit event.
            emit ProtocolDeposit(
                block.timestamp,
                batch.protocol,
                batch.amount,
                previousAmount,
                previousAmount + assetAmountReceived
            );
        }
    }

    /**
     * @notice Close a series of investments in batches for multiple protocols.
     * Calls target contracts with provided calldata to close positions.
     * @param batches Array of CloseBatch data containing protocol, users, contributions, token, and shares.
     */
    function close(CloseBatch[] memory batches) external onlyOwner {
        for (uint256 i = 0; i < batches.length; i++) {
            CloseBatch memory batch = batches[i];

            // Get the protocol asset details.
            Protocol memory protocol = protocols[batch.protocol];
            uint256 totalHoldings = protocol.assetAmount;

            // Calculate the amount to withdraw based on the ratio provided.
            uint256 amountToWithdraw = (totalHoldings * batch.ratio) / 1e8;
            // TODO

            // Update the protocol asset details.
            protocol.assetAmount -= amountToWithdraw;
            protocols[batch.protocol] = protocol;

            if (protocol.classification == ProtocolClassification.POSITION_MANAGER) {
                // Transfer relevant NFT position manager, if applicable.
                IERC721 nft = IERC721(protocol.assetAddress);
                nft.transferFrom(address(this), batch.protocol, protocol.nftId);
            } else {
                // Transfer tokens to the child contract.
                IERC20(protocol.assetAddress).transfer(batch.protocol, amountToWithdraw);
            }

            // Call the close function on the child contract.
            (bool success, uint256 tokenAmountReceived) = IQWComponent(batch.protocol).close(amountToWithdraw);
            if (!success) {
                revert CallFailed();
            }
            // TODO: Ensure tokens were transferred. Tokens received will be protocol.investmentToken.

            // Emit withdrawal event.
            emit ProtocolWithdrawal(block.timestamp, batch.protocol, batch.ratio, tokenAmountReceived);
        }
    }

    /**
     * @notice Withdraw funds to a specified user.
     * Transfers a specified amount of funds to the user.
     * @param _user The address of the user to receive the funds.
     * @param _tokenAddress The address of the token to transfer.
     * @param _amount The amount of funds to transfer to the user.
     */
    function withdraw(address _user, address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(_user, _amount);
    }

    /**
     * @notice Receive funds from a specified user.
     * Transfers a specified amount of funds from the user to this contract.
     * @param _user The address of the user sending the funds.
     * @param _tokenAddress The address of the token to transfer.
     * @param _amount The amount of funds to transfer to this contract.
     */
    function receiveFunds(address _user, address _tokenAddress, uint256 _amount) external {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(_user, address(this), _amount);
    }
}
