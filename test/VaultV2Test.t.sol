// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VaultV1} from "../src/VaultV1.sol";
import {VaultV2} from "../src/VaultV2.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VaultV2Test is Test {
    VaultV1 vault1;
    VaultV2 vault2;
    ERC20Mock testToken;

    address public proxy1;

    address public user1 = makeAddr("user");
    address public user2 = makeAddr("user2");
    address public owner = makeAddr("owner");

    uint256 DEPOSIT_AMOUNT = 100 ether;
    uint256 WITHDRAW_AMOUNT = 50 ether;
    uint256 vaultVersion = 2;
    uint256 APY = 10;
    uint256 minimumDeposit = 1 ether;

    error TransferFailed(address user, uint256 amount);

    function setUp() public {
        testToken = new ERC20Mock();
        testToken.mint(address(this), 1000 ether);

        // deploy vault1 and initialize token address and owner
        VaultV1 vaultV1Impl = new VaultV1();
        proxy1 = address(new ERC1967Proxy(address(vaultV1Impl), ""));
        vault1 = VaultV1(proxy1);
        vault1.initialize(address(testToken), owner);

        // deposit to Vault and track balance before upgrade
        testToken.mint(user1, DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        testToken.approve(proxy1, DEPOSIT_AMOUNT);
        vault1.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        console.log("User Balance before upgrade:", vault1.getBalance(user1));

        // deploy vault2 and upgrade
        VaultV2 vaultV2Impl = new VaultV2();
        // Encode the call to initializeV2
        bytes memory initData = abi.encodeWithSelector(
            VaultV2.initializeV2.selector,
            owner,
            APY,
            minimumDeposit
        );
        // Impersonate owner to upgrade and initialize
        vm.prank(owner);
        vault1.upgradeToAndCall(address(vaultV2Impl), initData);

        vault2 = VaultV2(proxy1);
        // to test if storage in proxy will be intact after running upgrade
        console.log("User Balance after upgrade: ", vault2.getBalance(user1));
        //console.log("User Timestamp after upgrade: ", vault2.getUserTimestamp(user1) + 60 days);
    }

    function testOnlyOwnerHasBeenImplementedV2() public {
        vm.startPrank(user1);
        vm.expectRevert(); // Expect it to fail for non-owner
        vault2.getVaultVersion();
        vm.stopPrank();
    }

    function testGetCorrectVaultVersion() public {
        vm.prank(owner);
        uint256 version = vault2.getVaultVersion();
        assertEq(version, vaultVersion);
    }

    function testUserCannotDepositBelowMinimumAmount() public {
        testToken.mint(user2, DEPOSIT_AMOUNT);
        vm.startPrank(user2);
        testToken.approve(proxy1, 0.1 ether);
        vm.expectRevert(VaultV2.InsufficientDeposit.selector);
        vault1.deposit(0.1 ether);
        vm.stopPrank();
    }

    function testGetCorrectAPY() public view {
        uint256 _APY = vault2.getAPY();
        assertEq(_APY, 10e18);
    }

    function testWithdrawV2() public {
        vm.startPrank(user1);
        vm.warp(vault2.getUserTimestamp(user1) + 70 days);
        uint256 usersInterest = vault2.getUserAccruedInterest(user1);
        vault2.withdraw(WITHDRAW_AMOUNT);

        assertEq(
            vault2.getBalance(user1),
            ((DEPOSIT_AMOUNT + usersInterest) - WITHDRAW_AMOUNT)
        );
    }

    function testZeroWithdrawalV2() public {
        vm.startPrank(user2);
        vm.warp(vault2.getUserTimestamp(user1) + 70 days);
        vm.expectRevert(VaultV2.ZeroWithdraw.selector);
        vault1.withdraw(0);
        vm.stopPrank();
    }

    function testUserCannotWithdrawAboveBalancePlusInterest() public {
        vm.startPrank(user1);
        vm.warp(vault2.getUserTimestamp(user1) + 70 days);
        vm.expectRevert(VaultV1.InsufficientBalance.selector);
        vault1.withdraw(DEPOSIT_AMOUNT + 100 ether);
        vm.stopPrank();
    }

    function testWithdrawalEventEmittedV2() public {
        vm.startPrank(user1);
        vm.warp(vault2.getUserTimestamp(user1) + 70 days);
        vm.expectEmit(true, true, true, true);
        emit VaultV1.VaultV1_Withdrawn(user1, WITHDRAW_AMOUNT);
        vault1.withdraw(WITHDRAW_AMOUNT);
        vm.stopPrank();
    }

    function testTimeHasNotElapsedToWithdraw() public {
        vm.startPrank(user1);

        vm.expectRevert(VaultV2.TimeHasNotElapsedToWithdraw.selector);

        vault2.withdraw(WITHDRAW_AMOUNT);
        vm.stopPrank();
    }
}
