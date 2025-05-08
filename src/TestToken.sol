// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20,  AccessControl {
    constructor(address defaultAdmin)
        ERC20("TestToken", "TTK")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }
    
    function mint(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }
}
