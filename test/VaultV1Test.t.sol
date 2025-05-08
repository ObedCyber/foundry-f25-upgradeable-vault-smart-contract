// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VaultV1} from "../src/VaultV1.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VaultV1Test is Test {
    VaultV1 vault1;
    ERC20Mock testToken;

    address public proxy;

    address public user1 = makeAddr("user");
    address public owner = makeAddr("owner");

    uint256 DEPOSIT_AMOUNT = 100 ether;
    uint256 WITHDRAW_AMOUNT = 50 ether;

    error TransferFailed(address user, uint256 amount);

    function setUp() public {
        testToken = new ERC20Mock();
        VaultV1 vaultV1Impl = new VaultV1();

        proxy = address(new ERC1967Proxy(address(vaultV1Impl), ""));
        vault1 = VaultV1(proxy);
        vault1.initialize(address(testToken), owner);
    }

    function testOnlyOwnerHasBeenImplemented() public {
        // check if another address can call vault version
        vm.startPrank(user1);
        vm.expectRevert();
        VaultV1(proxy).getVaultVersion();
        vm.stopPrank();
    }

    function testDeposit() public {
        testToken.mint(user1, DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        testToken.approve(proxy, DEPOSIT_AMOUNT);
        vault1.deposit(DEPOSIT_AMOUNT);
        assertEq(vault1.getBalance(user1), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testWithdrawal() public {
        testToken.mint(user1, DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        testToken.approve(proxy, DEPOSIT_AMOUNT);
        vault1.deposit(DEPOSIT_AMOUNT);
        vault1.withdraw(WITHDRAW_AMOUNT);
        assertEq(vault1.getBalance(user1), 50 ether);
        vm.stopPrank();
    }

    function testCannotDepositZero() public {
        vm.startPrank(user1);
        vm.expectRevert(VaultV1.ZeroDeposit.selector);
        vault1.deposit(0);
        vm.stopPrank();
    }

    function testDepositEmitsEvent() public {
        testToken.mint(user1, DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        testToken.approve(proxy, DEPOSIT_AMOUNT);
        vm.expectEmit(true, true, true, true); 
        emit VaultV1.VaultV1_Deposited(user1, DEPOSIT_AMOUNT); 
        vault1.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testZeroWithdrawal() public {
        vm.startPrank(user1);
        vm.expectRevert();
        vault1.withdraw(0);
        vm.stopPrank();
    }

    function testUserCannotWithdrawAboveBalance() public {
        testToken.mint(user1, DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        testToken.approve(proxy, DEPOSIT_AMOUNT);
        vault1.deposit(DEPOSIT_AMOUNT);
        vm.expectRevert(VaultV1.InsufficientBalance.selector);
        vault1.withdraw(DEPOSIT_AMOUNT + 100 ether);
        vm.stopPrank();
    }

    function testWithdrawalEventEmitted() public{
        testToken.mint(user1, DEPOSIT_AMOUNT);
        vm.startPrank(user1);
        testToken.approve(proxy, DEPOSIT_AMOUNT);
        vault1.deposit(DEPOSIT_AMOUNT);
        vm.expectEmit(true, true, true, true); 
        emit VaultV1.VaultV1_Withdrawn(user1, WITHDRAW_AMOUNT); 
        vault1.withdraw(WITHDRAW_AMOUNT);
        vm.stopPrank();
    }

}
