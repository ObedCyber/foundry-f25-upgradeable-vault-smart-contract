// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TestToken} from "../src/TestToken.sol";

contract TestTokenTest is Test {
    TestToken token;
    address admin = address(1);
    address user = address(2);

    function setUp() public {
        vm.prank(admin);
        token = new TestToken(admin);
    }

    function testConstructorGrantsAdminRole() view public {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
    }

    function testAdminCanMint() public {
        uint256 amount = 1000 ether;

        vm.prank(admin);
        token.mint(user, amount);

        assertEq(token.balanceOf(user), amount);
    }

    function testNonAdminCannotMint() public {
    uint256 amount = 1000 ether;

    vm.prank(user);
    vm.expectRevert();
    token.mint(user, amount);
}
}
