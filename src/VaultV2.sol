// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VaultV2
 * @author Obed Okoh
 * @notice VaultV2 is a simple vault contract that allows users to deposit and withdraw tokens.
 * It is an upgrade of VaultV1 and includes additional features such as:
 * - APY (Annual Rate of Yield) calculation for user deposits.
 * - Minimum deposit amount requirement.
 * - Improved error handling for deposit and withdrawal functions.
 * It uses the UUPS proxy pattern for upgradability and is protected against reentrancy attacks.
 */
contract VaultV2 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuard
{
    IERC20 public token;
    mapping(address => uint256) userBalances;

    uint256 public APY; // Annual Rate of Yield
    uint256 public constant APY_PRECISION = 1e18; // Precision for APY calculations
    uint256 public minimumDeposit;

    mapping(address => uint256) userTimestamps;

    // Events from (VaultV1)
    event VaultV1_Upgraded(address newImplementation);
    event VaultV1_Deposited(address indexed user, uint256 amount);
    event VaultV1_Withdrawn(address indexed user, uint256 amount);

    // Errors from (VaultV1)
    error ZeroDeposit();
    error ZeroWithdraw();
    error InsufficientBalance();
    error TransferFailed();
    error InsufficientDeposit();
    // Error from (VaultV2)
    error TimeHasNotElapsedToWithdraw();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * initializeV2 function is used to initialize the contract.
     * It sets the token address, APY, and minimum deposit amount.
     * It initializes the Ownable and UUPS modules.
     * @param _APY The annual percentage yield (APY) for the vault.
     * @param _minimumDeposit  The minimum deposit amount required to use the vault.
     */
    function initializeV2(
        address owner,
        uint256 _APY,
        uint256 _minimumDeposit
    ) public reinitializer(2) {
        __Ownable_init(owner);
        __UUPSUpgradeable_init();

        APY = _APY * APY_PRECISION;
        minimumDeposit = _minimumDeposit;
    }

    /**
     * _authorizeUpgrade function is used to authorize the upgrade of the contract.
     * It is called by the UUPS proxy when an upgrade is requested.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override  {
        emit VaultV1_Upgraded(newImplementation);
    }

    /**
     * deposit function allows users to deposit tokens into the vault.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) public payable {
        if (amount == 0) revert ZeroDeposit();
        if (amount < minimumDeposit) revert InsufficientDeposit();

        address user = msg.sender;
        userBalances[user] += amount;
        if (userBalances[user] == 0 || userTimestamps[user] == 0) {
            userTimestamps[user] = block.timestamp;
        }

        bool success = token.transferFrom(user, address(this), amount);
        if (!success) revert TransferFailed();

        emit VaultV1_Deposited(user, amount);
    }

    /**
     * withdraw function allows users to withdraw tokens from the vault.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) public nonReentrant {
        address user = msg.sender;

        uint256 accruedInterest = getUserAccruedInterest(user);
        userBalances[user] += accruedInterest;

        uint256 balance = userBalances[user];

        if (amount == 0) revert ZeroWithdraw();
        if (amount > balance) revert InsufficientBalance();

        if (block.timestamp - userTimestamps[user] > 60 days) {
            userBalances[user] -= amount;

            bool success = token.transfer(user, amount);
            if (!success) revert TransferFailed();

            emit VaultV1_Withdrawn(user, amount);

            userTimestamps[user] = block.timestamp;
        } else {
            revert TimeHasNotElapsedToWithdraw();
        }
    }

    function getUserAccruedInterest(
        address user
    ) public view returns (uint256) {
        uint256 balance = userBalances[user];
        uint256 timeElapsed = block.timestamp - userTimestamps[user];
        uint256 interest = (balance * APY * timeElapsed) /
            (365 days * APY_PRECISION * 100);
        return interest;
        //Balance after 70 days: 100,00000000,0000000000
        // 100e18 * (10e18 / 1e20) * (70/365)
        //Interest after 70 days: 1.91780821,9178082191
    }

    /**
     * getBalance function returns the balance of a user in the vault.
     * @param user The address of the user whose balance to check.
     * retuns The balance of the user in the vault.
     */
    function getBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    function getUserTimestamp(address user) external view returns (uint256) {
        return userTimestamps[user];
    }

    /**
     * getVaultVersion function returns the version of the vault contract.
     * @return The version of the vault contract.
     */
    function getVaultVersion() external view onlyOwner returns (uint256) {
        return _getInitializedVersion();
    }

    function getAPY() external view returns (uint256) {
        return APY;
    }
}
