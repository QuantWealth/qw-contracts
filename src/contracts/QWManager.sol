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
    struct ComponentNft {
        address nftContract;
        uint256 nftId;
    }

    // Variables
    address public immutable REGISTRY;

    // Tracks component assets and other information.
    mapping(address => mapping(address => uint256)) public componentAssets;
    mapping(address => ComponentNft) public componentPositionManagers;

    event ProtocolDeposit(
        uint256 indexed epoch,
        address indexed component,
        address asset,
        uint256 amount,
        uint256 previousTotalHoldings,
        uint256 newTotalHoldings
    );
    event ProtocolWithdrawal(
        uint256 indexed epoch,
        address indexed component,
        address asset,
        uint256 amount,
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
     * @notice Execute a series of investments in batches for multiple components.
     * Transfers specified amounts of tokens and calls target contracts with provided calldata.
     * @param batches Array of OpenBatch data containing component, users, contributions, token, amount, and asset.
     */
    function open(OpenBatch[] memory batches) external onlyOwner {
        for (uint256 i = 0; i < batches.length; i++) {
            OpenBatch memory batch = batches[i];

            // Check if the target contract is whitelisted
            if (!IQWRegistry(REGISTRY).whitelist(batch.component)) {
                revert ContractNotWhitelisted();
            }

            // Get the current holdings of the asset.
            uint256 previousAmount = componentAssets[batch.component][batch.asset];

            // Approve the target contract to spend the specified amount of tokens.
            IERC20 token = IERC20(batch.token);
            token.approve(address(batch.component), batch.amount);

            // Transfer relevant NFT position manager, if applicable.
            ComponentNft memory positionManager = componentPositionManagers[batch.component];
            if (positionManager.nftContract != address(0)) {
                IERC721 nft = IERC721(positionManager.nftContract);
                nft.transferFrom(address(this), batch.component, positionManager.nftId);
            }

            // Call the open function on the target contract with the provided calldata.
            (bool success, uint256 assetAmountReceived) = IQWComponent(batch.component).open(batch.amount, batch.asset);
            if (!success) {
                // TODO: Event for batches that fail.
                revert CallFailed();
            }
            // TODO: Ensure protocol asset correct amount was transferred.

            // Update the component's asset holdings.
            componentAssets[batch.component][batch.asset] = previousAmount + assetAmountReceived;

            // Emit deposit event.
            emit ProtocolDeposit(
                block.timestamp,
                batch.component,
                batch.asset,
                batch.amount,
                previousAmount,
                previousAmount + assetAmountReceived
            );
        }
    }

    /**
     * @notice Close a series of investments in batches for multiple components.
     * Calls target contracts with provided calldata to close positions.
     * @param batches Array of CloseBatch data containing component, users, contributions, token, shares, and asset.
     */
    function close(CloseBatch[] memory batches) external onlyOwner {
        for (uint256 i = 0; i < batches.length; i++) {
            CloseBatch memory batch = batches[i];

            // Get the current holdings of the asset.
            uint256 totalHoldings = componentAssets[batch.component][batch.asset];

            // Calculate the amount to withdraw based on the ratio provided.
            uint256 amountToWithdraw = (totalHoldings * batch.ratio) / 1e8;

            // Update the component's asset holdings.
            componentAssets[batch.component][batch.asset] -= amountToWithdraw;

            // Transfer relevant NFT position manager, if applicable.
            ComponentNft memory positionManager = componentPositionManagers[batch.component];
            if (positionManager.nftContract != address(0)) {
                IERC721 nft = IERC721(positionManager.nftContract);
                nft.transferFrom(address(this), batch.component, positionManager.nftId);
            } else {
                // Transfer tokens to the child contract.
                IERC20(batch.asset).transfer(batch.component, amountToWithdraw);
            }

            // Call the close function on the child contract.
            (bool success, uint256 tokenAmountReceived) = IQWComponent(batch.component).close(amountToWithdraw, batch.asset);
            if (!success) {
                revert CallFailed();
            }
            // TODO: Ensure tokens were transferred. Tokens received will be batch.token.

            // Emit withdrawal event.
            emit ProtocolWithdrawal(
                block.timestamp,
                batch.component,
                batch.asset,
                amountToWithdraw,
                tokenAmountReceived
            );
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

    /**
     * @notice Set a protocol in storage without erasing an existing entry.
     * @param component The address of the component.
     * @param nftContract The address of the NFT contract.
     * @param nftId The ID of the NFT.
     */
    function setComponentPositionManager(
        address component,
        address nftContract,
        uint256 nftId
    ) external onlyOwner {
        ComponentNft storage positionManager = componentPositionManagers[component];
        positionManager.nftContract = nftContract;
        positionManager.nftId = nftId;
    }
}
