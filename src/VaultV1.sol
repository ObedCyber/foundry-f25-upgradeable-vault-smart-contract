// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VaultV1
 * @author Obed Okoh
 * @notice VaultV1 is a simple vault contract that allows users to deposit and withdraw tokens.
 * It uses the UUPS proxy pattern for upgradability and is protected against reentrancy attacks.
 */
contract VaultV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard  {
    IERC20 public token;
    mapping(address => uint256) userBalances;


    // Events
    event VaultV1_Upgraded(address newImplementation);
    event VaultV1_Deposited(address indexed user, uint256 amount);
    event VaultV1_Withdrawn(address indexed user, uint256 amount);

    // Errors
    error ZeroDeposit();
    error ZeroWithdraw();
    error InsufficientBalance();
    error TransferFailed(address user, uint256 amount);
    error withdrawalFailed(address user, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    /**
     * initialize function is used to initialize the contract.
     * It sets the token address and initializes the Ownable and UUPS modules.
     * @param _tokenAddress The address of the token contract to be used for deposits and withdrawals.
     */
    function initialize(address _tokenAddress, address owner) public initializer {
        __Ownable_init(owner);
        __UUPSUpgradeable_init();

        token = IERC20(_tokenAddress);
    }

    /**
     * _authorizeUpgrade function is used to authorize the upgrade of the contract.
     * It is called by the UUPS proxy when an upgrade is requested.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override {
        emit VaultV1_Upgraded(newImplementation);
    }

    /**
     * deposit function allows users to deposit tokens into the vault.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) public {
        if (amount == 0) revert ZeroDeposit();

        address user = msg.sender;
        userBalances[user] += amount;

        bool success = token.transferFrom(user, address(this), amount);
        if (!success) revert TransferFailed(user, amount);

        emit VaultV1_Deposited(user, amount);
    }

    /**
     * withdraw function allows users to withdraw tokens from the vault.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) public nonReentrant  {
        if (amount == 0) revert ZeroWithdraw();

        address user = msg.sender;

        uint256 balance = userBalances[user];
        if (balance < amount) revert InsufficientBalance();

        balance -= amount;
        userBalances[user] = balance;

        bool success = token.transfer(user, amount);
        if (!success) revert withdrawalFailed(user, amount);

        emit VaultV1_Withdrawn(user, amount);
    }

    /**
     * getBalance function returns the balance of a user in the vault.
     * @param user The address of the user whose balance to check.
     * retuns The balance of the user in the vault.
     */
     function getBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }
    /**
     * getVaultVersion function returns the version of the vault contract.
     * @return The version of the vault contract.
     */
    function getVaultVersion() external view onlyOwner returns  (uint256) {
        return 1;
    }
}
